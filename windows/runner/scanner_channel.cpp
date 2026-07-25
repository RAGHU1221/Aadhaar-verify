// See scanner_channel.h for setup instructions.
//
// Implements two MethodChannel calls on 'aadhaar_verifier/scanner':
//   listScanners() -> List<{id, name}>
//   scanPage({deviceId, outputPath}) -> bool
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
bool ScanOnePage(const std::wstring& deviceId, const std::wstring& outputPath) {
  CComPtr<IWiaDevMgr2> devMgr;
  HRESULT hr = devMgr.CoCreateInstance(CLSID_WiaDevMgr2);
  if (FAILED(hr)) return false;

  CComPtr<IWiaItem2> rootItem;
  hr = devMgr->CreateDevice(0, const_cast<BSTR>(deviceId.c_str()), &rootItem);
  if (FAILED(hr) || !rootItem) return false;

  // Enumerate to the first scannable child item (flatbed/feeder image item).
  CComPtr<IEnumWiaItem2> enumItem;
  hr = rootItem->EnumChildItems(nullptr, &enumItem);
  if (FAILED(hr) || !enumItem) return false;

  CComPtr<IWiaItem2> imageItem;
  hr = enumItem->Next(1, &imageItem, nullptr);
  if (FAILED(hr) || !imageItem) {
    // Some drivers expose the root itself as the transferable item.
    imageItem = rootItem;
  }

  CComPtr<IWiaTransfer> transfer;
  hr = imageItem->QueryInterface(IID_IWiaTransfer, (void**)&transfer);
  if (FAILED(hr) || !transfer) return false;

  // Minimal IWiaTransferCallback that just records success/failure.
  class SimpleCallback : public IWiaTransferCallback {
   public:
    std::wstring targetPath;
    bool succeeded = false;
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
      SHCreateStreamOnFileEx(targetPath.c_str(), STGM_CREATE | STGM_WRITE, FILE_ATTRIBUTE_NORMAL,
                              TRUE, nullptr, stream);
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
  callback->Release();
  return ok;
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
          bool ok = ScanOnePage(deviceId, outputPath);
          result->Success(EncodableValue(ok));

        } else {
          result->NotImplemented();
        }
      });

  // Leak the channel intentionally (it must outlive the engine callback
  // registration; the Flutter Windows embedder pattern keeps such
  // channels alive for the app's lifetime).
  channel.release();
}
