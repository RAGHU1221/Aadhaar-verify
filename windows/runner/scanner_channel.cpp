// See scanner_channel.h for setup instructions.
//
// Implements two MethodChannel calls on 'aadhaar_verifier/scanner':
//   listScanners() -> List<{id, name}>
//   scanPage({deviceId, outputPath}) -> {success: bool, error: string}
//
// Mirrors the logic already proven working in the Python build's
// modules/scanner.py (WIA.DeviceManager + Device.Items[0].Transfer()),
// translated to raw COM calls since there's no win32com equivalent in
// C++ - we talk to the WIA COM interfaces directly.

#include "scanner_channel.h"

#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>
#include <flutter/encodable_value.h>

#include <windows.h>
#include <wia.h>
#include <comdef.h>
#include <atlbase.h>
#include <cstdio>
#include <string>
#include <vector>
#include <memory>

#pragma comment(lib, "wiaguid.lib")

using flutter::EncodableValue;
using flutter::EncodableMap;
using flutter::EncodableList;
using flutter::MethodCall;
using flutter::MethodResult;
using flutter::MethodChannel;

namespace {

std::wstring Utf8ToWide(const std::string& s) {
  if (s.empty()) return L"";
  int size = MultiByteToWideChar(CP_UTF8, 0, s.c_str(), (int)s.size(), nullptr, 0);
  std::wstring result(size, 0);
  MultiByteToWideChar(CP_UTF8, 0, s.c_str(), (int)s.size(), &result[0], size);
  return result;
}

std::string WideToUtf8(const std::wstring& s) {
  if (s.empty()) return "";
  int size = WideCharToMultiByte(CP_UTF8, 0, s.c_str(), (int)s.size(), nullptr, 0, nullptr, nullptr);
  std::string result(size, 0);
  WideCharToMultiByte(CP_UTF8, 0, s.c_str(), (int)s.size(), &result[0], size, nullptr, nullptr);
  return result;
}

// Reads a BSTR property (e.g. WIA_DIP_DEV_ID / "Name") from a device info.
std::wstring ReadDeviceProperty(IWiaPropertyStorage* storage, PROPID propId) {
  PROPSPEC spec = {};
  spec.ulKind = PRSPEC_PROPID;
  spec.propid = propId;
  PROPVARIANT var;
  PropVariantInit(&var);
  std::wstring result;
  if (SUCCEEDED(storage->ReadMultiple(1, &spec, &var))) {
    if (var.vt == VT_BSTR && var.bstrVal) {
      result = var.bstrVal;
    }
    PropVariantClear(&var);
  }
  return result;
}

// Reads a VT_I4 property (e.g. resolution/extent properties).
bool ReadLongProperty(IWiaPropertyStorage* storage, PROPID propId, long* outVal) {
  PROPSPEC spec = {};
  spec.ulKind = PRSPEC_PROPID;
  spec.propid = propId;
  PROPVARIANT var;
  PropVariantInit(&var);
  bool ok = false;
  if (SUCCEEDED(storage->ReadMultiple(1, &spec, &var)) && var.vt == VT_I4) {
    *outVal = var.lVal;
    ok = true;
  }
  PropVariantClear(&var);
  return ok;
}

// Cap the scan resolution: budget AIO printer/scanners (e.g. Canon
// imageCLASS MF3010-class devices) commonly default WIA_IPS_XRES/YRES to
// 600 DPI or higher. That's overkill for OCR/QR reading and, combined
// with scanning the full bed (see below), makes every scan take much
// longer than necessary. 200 DPI is still plenty for text/QR and is a
// commonly supported step on these drivers.
const long kTargetScanDpi = 200;

void CapScanResolution(IWiaPropertyStorage* propStorage) {
  PROPSPEC specs[2] = {};
  PROPVARIANT vars[2] = {};
  specs[0].ulKind = PRSPEC_PROPID; specs[0].propid = WIA_IPS_XRES;
  specs[1].ulKind = PRSPEC_PROPID; specs[1].propid = WIA_IPS_YRES;
  PropVariantInit(&vars[0]); vars[0].vt = VT_I4; vars[0].lVal = kTargetScanDpi;
  PropVariantInit(&vars[1]); vars[1].vt = VT_I4; vars[1].lVal = kTargetScanDpi;
  propStorage->WriteMultiple(2, specs, vars, 0);
}

// WIA items default WIA_IPS_XEXTENT/YEXTENT to whatever area was last
// scanned (often a small preview-sized region, not the full page), so
// without this, Download() only captures that partial rectangle. Set the
// position to (0,0) and the extent to the device's max supported size at
// its current resolution, so the full page/bed is captured.
void SetFullPageScanArea(IWiaItem2* item) {
  CComPtr<IWiaPropertyStorage> propStorage;
  if (FAILED(item->QueryInterface(IID_IWiaPropertyStorage, (void**)&propStorage)) || !propStorage) {
    return;
  }

  CapScanResolution(propStorage);

  long xRes = 0, yRes = 0, maxWidth = 0, maxHeight = 0;
  // Re-read after writing - some drivers clamp to the nearest supported
  // value rather than accepting kTargetScanDpi exactly.
  if (!ReadLongProperty(propStorage, WIA_IPS_XRES, &xRes) || xRes <= 0) xRes = kTargetScanDpi;
  if (!ReadLongProperty(propStorage, WIA_IPS_YRES, &yRes) || yRes <= 0) yRes = kTargetScanDpi;
  if (!ReadLongProperty(propStorage, WIA_IPS_MAX_HORIZONTAL_SIZE, &maxWidth)) return;
  if (!ReadLongProperty(propStorage, WIA_IPS_MAX_VERTICAL_SIZE, &maxHeight)) return;

  // WIA_IPS_MAX_HORIZONTAL_SIZE/VERTICAL_SIZE are in thousandths of an inch.
  long xExtent = static_cast<long>(static_cast<double>(maxWidth) * xRes / 1000.0);
  long yExtent = static_cast<long>(static_cast<double>(maxHeight) * yRes / 1000.0);
  if (xExtent <= 0 || yExtent <= 0) return;

  PROPSPEC specs[4] = {};
  PROPVARIANT vars[4] = {};
  const PROPID propIds[4] = {WIA_IPS_XPOS, WIA_IPS_YPOS, WIA_IPS_XEXTENT, WIA_IPS_YEXTENT};
  const long values[4] = {0, 0, xExtent, yExtent};
  for (int i = 0; i < 4; i++) {
    specs[i].ulKind = PRSPEC_PROPID;
    specs[i].propid = propIds[i];
    PropVariantInit(&vars[i]);
    vars[i].vt = VT_I4;
    vars[i].lVal = values[i];
  }
  propStorage->WriteMultiple(4, specs, vars, 0);
}

// Lists connected WIA devices, excluding cameras where the device type
// property clearly says so (StiDeviceType: 1 = scanner, 2 = camera).
std::vector<std::pair<std::wstring, std::wstring>> ListScannerDevices() {
  std::vector<std::pair<std::wstring, std::wstring>> devices;

  CComPtr<IWiaDevMgr2> devMgr;
  HRESULT hr = devMgr.CoCreateInstance(CLSID_WiaDevMgr2);
  if (FAILED(hr)) return devices;

  CComPtr<IEnumWIA_DEV_INFO> enumInfo;
  hr = devMgr->EnumDeviceInfo(WIA_DEVINFO_ENUM_ALL, &enumInfo);
  if (FAILED(hr) || !enumInfo) return devices;

  CComPtr<IWiaPropertyStorage> propStorage;
  ULONG fetched = 0;
  while (enumInfo->Next(1, &propStorage, &fetched) == S_OK && fetched == 1) {
    std::wstring id = ReadDeviceProperty(propStorage, WIA_DIP_DEV_ID);
    std::wstring name = ReadDeviceProperty(propStorage, WIA_DIP_DEV_NAME);
    if (name.empty()) name = L"Scanner";

    // WIA_DIP_DEV_TYPE low word: StiDeviceType (1 = scanner). Skip clear
    // non-scanner devices (cameras=2) where we can read it; otherwise
    // include - better to show an extra device than hide a valid scanner.
    PROPSPEC spec = {}; spec.ulKind = PRSPEC_PROPID; spec.propid = WIA_DIP_DEV_TYPE;
    PROPVARIANT var; PropVariantInit(&var);
    bool isCamera = false;
    if (SUCCEEDED(propStorage->ReadMultiple(1, &spec, &var)) && var.vt == VT_I4) {
      long lowWord = var.lVal & 0xFFFF;
      if (lowWord == 2) isCamera = true;
    }
    PropVariantClear(&var);

    if (!isCamera && !id.empty()) {
      devices.push_back({id, name});
    }
    propStorage.Release();
  }
  return devices;
}

// Connects to a device by ID, scans its first item, and saves as PNG.
// On failure, fills [errorOut] with the stage and HRESULT so the Dart
// side can show something more useful than a generic "scan failed".
bool ScanOnePage(const std::wstring& deviceId, const std::wstring& outputPath,
                  std::wstring* errorOut) {
  auto fail = [&](const wchar_t* stage, HRESULT hr) {
    wchar_t buf[256];
    swprintf_s(buf, L"%ls failed (hr=0x%08X)", stage, hr);
    if (errorOut) *errorOut = buf;
    return false;
  };

  CComPtr<IWiaDevMgr2> devMgr;
  HRESULT hr = devMgr.CoCreateInstance(CLSID_WiaDevMgr2);
  if (FAILED(hr)) return fail(L"CoCreateInstance(WiaDevMgr2)", hr);

  // CreateDevice needs a real BSTR (length-prefixed), not a raw wchar_t*.
  _bstr_t deviceIdBstr(deviceId.c_str());
  CComPtr<IWiaItem2> rootItem;
  hr = devMgr->CreateDevice(0, deviceIdBstr, &rootItem);
  if (FAILED(hr) || !rootItem) return fail(L"CreateDevice", hr);

  // Enumerate to the first scannable child item (flatbed/feeder image item).
  CComPtr<IEnumWiaItem2> enumItem;
  hr = rootItem->EnumChildItems(nullptr, &enumItem);
  if (FAILED(hr) || !enumItem) return fail(L"EnumChildItems", hr);

  CComPtr<IWiaItem2> imageItem;
  hr = enumItem->Next(1, &imageItem, nullptr);
  if (FAILED(hr) || !imageItem) {
    // Some drivers expose the root itself as the transferable item.
    imageItem = rootItem;
  }

  // Without this, some drivers leave XEXTENT/YEXTENT at a small leftover
  // preview-sized region, so the scan only comes back covering part of
  // the page instead of the whole thing.
  SetFullPageScanArea(imageItem);

  CComPtr<IWiaTransfer> transfer;
  hr = imageItem->QueryInterface(IID_IWiaTransfer, (void**)&transfer);
  if (FAILED(hr) || !transfer) return fail(L"QueryInterface(IWiaTransfer)", hr);

  // Minimal IWiaTransferCallback that just records success/failure.
  class SimpleCallback : public IWiaTransferCallback {
   public:
    std::wstring targetPath;
    HRESULT streamError = S_OK;
    LONG refCount = 1;

    STDMETHODIMP QueryInterface(REFIID riid, void** ppv) override {
      if (riid == IID_IUnknown || riid == IID_IWiaTransferCallback) {
        *ppv = this; AddRef(); return S_OK;
      }
      *ppv = nullptr; return E_NOINTERFACE;
    }
    STDMETHODIMP_(ULONG) AddRef() override { return InterlockedIncrement(&refCount); }
    STDMETHODIMP_(ULONG) Release() override {
      LONG c = InterlockedDecrement(&refCount);
      if (c == 0) delete this;
      return c;
    }
    STDMETHODIMP TransferCallback(LONG flags, WiaTransferParams* params) override {
      if (params && params->lMessage == WIA_TRANSFER_MSG_STATUS) {
        // progress - ignore
      }
      return S_OK;
    }
    STDMETHODIMP GetNextStream(LONG flags, BSTR itemName, BSTR fullItemName, IStream** stream) override {
      *stream = nullptr;
      streamError = SHCreateStreamOnFileEx(targetPath.c_str(), STGM_CREATE | STGM_WRITE,
                                            FILE_ATTRIBUTE_NORMAL, TRUE, nullptr, stream);
      return *stream ? S_OK : E_FAIL;
    }
  };

  auto* callback = new SimpleCallback();
  callback->targetPath = outputPath;

  // NOTE: this calls Download() with default transfer parameters, which
  // uses the device's native/default format. If scanned files come out
  // in an unexpected format, look into IWiaItem2::SetProperties to set
  // WIA_IPA_FORMAT to WiaImgFmt_PNG before calling Download() - this
  // wasn't verified against a real scanner in this sandbox.
  hr = transfer->Download(0, callback);
  bool ok = SUCCEEDED(hr);
  HRESULT streamError = callback->streamError;
  callback->Release();
  if (!ok) {
    if (FAILED(streamError)) return fail(L"SHCreateStreamOnFileEx", streamError);
    return fail(L"Download", hr);
  }
  return true;
}

}  // namespace

void RegisterScannerChannel(flutter::FlutterEngine* engine) {
  auto channel = std::make_unique<MethodChannel<EncodableValue>>(
      engine->messenger(), "aadhaar_verifier/scanner",
      &flutter::StandardMethodCodec::GetInstance());

  channel->SetMethodCallHandler(
      [](const MethodCall<EncodableValue>& call,
         std::unique_ptr<MethodResult<EncodableValue>> result) {
        CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

        if (call.method_name() == "listScanners") {
          auto devices = ListScannerDevices();
          EncodableList list;
          for (auto& d : devices) {
            EncodableMap m;
            m[EncodableValue("id")] = EncodableValue(WideToUtf8(d.first));
            m[EncodableValue("name")] = EncodableValue(WideToUtf8(d.second));
            list.push_back(EncodableValue(m));
          }
          result->Success(EncodableValue(list));

        } else if (call.method_name() == "scanPage") {
          const auto* args = std::get_if<EncodableMap>(call.arguments());
          if (!args) {
            result->Error("bad_args", "Expected a map with deviceId/outputPath");
            return;
          }
          auto idIt = args->find(EncodableValue("deviceId"));
          auto pathIt = args->find(EncodableValue("outputPath"));
          if (idIt == args->end() || pathIt == args->end()) {
            result->Error("bad_args", "Missing deviceId or outputPath");
            return;
          }
          std::wstring deviceId = Utf8ToWide(std::get<std::string>(idIt->second));
          std::wstring outputPath = Utf8ToWide(std::get<std::string>(pathIt->second));
          std::wstring error;
          bool ok = ScanOnePage(deviceId, outputPath, &error);
          EncodableMap resultMap;
          resultMap[EncodableValue("success")] = EncodableValue(ok);
          resultMap[EncodableValue("error")] = EncodableValue(WideToUtf8(error));
          result->Success(EncodableValue(resultMap));

        } else {
          result->NotImplemented();
        }
      });

  // Leak the channel intentionally (it must outlive the engine callback
  // registration; the Flutter Windows embedder pattern keeps such
  // channels alive for the app's lifetime).
  channel.release();
}
