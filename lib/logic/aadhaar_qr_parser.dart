// Aadhaar / DigiLocker QR parser - ported from Python `modules/aadhaar_qr.py`.
//
// IMPORTANT HONESTY NOTE (read before editing):
// There are two Aadhaar QR generations in circulation:
//   1. OLD QR (pre-2019 cards/letters) -> plain XML text, human readable.
//      We parse this directly and with 100% confidence.
//   2. SECURE QR (2019 onwards) -> compressed + digitally signed binary blob.
//      We can decompress and read the demographic fields, BUT we do NOT
//      verify UIDAI's RSA signature here because that needs UIDAI's official
//      public certificate. Until that certificate is wired in, this tool
//      must NEVER report a Secure QR as "cryptographically verified" - it
//      only reports "structure parsed successfully", a much weaker claim.
//
// Notes are returned as i18n message keys (see lib/i18n/strings.dart) so
// the UI/PDF can render them bilingually.

import 'dart:convert';
import 'dart:io' show zlib;
import 'package:xml/xml.dart' as xml;

// Aadhaar QR XML attribute -> our field-label i18n key
const Map<String, String> kFieldKeyMap = {
  'name': 'field_name',
  'gender': 'field_gender',
  'yob': 'field_yob',
  'address_co': 'field_address_co',
  'house': 'field_house',
  'street': 'field_street',
  'district': 'field_district',
  'state': 'field_state',
  'pincode': 'field_pincode',
  'uid_last4': 'field_uid_last4',
};

class AadhaarQrResult {
  final String qrGeneration; // OLD_XML | SECURE_QR | DIGILOCKER | UNKNOWN
  final String signatureStatus; // NOT_CHECKED | STRUCTURE_ONLY | VERIFIED
  final Map<String, String> fields; // i18n field key -> value
  final String noteKey;
  final Map<String, String> noteParams;

  AadhaarQrResult({
    required this.qrGeneration,
    required this.signatureStatus,
    required this.fields,
    required this.noteKey,
    this.noteParams = const {},
  });
}

AadhaarQrResult parseAadhaarQr(String rawData) {
  final raw = rawData.trim();

  // --- Case 1: DigiLocker issued-document QR (URL based) ---
  if (raw.startsWith('http://') || raw.startsWith('https://')) {
    return AadhaarQrResult(
      qrGeneration: 'DIGILOCKER',
      signatureStatus: 'NOT_CHECKED',
      fields: {'field_digilocker_verify_url': raw},
      noteKey: 'note_digilocker',
    );
  }

  // --- Case 2: OLD Aadhaar QR - plain XML ---
  if (raw.trimLeft().startsWith('<')) {
    try {
      final doc = xml.XmlDocument.parse(raw);
      final root = doc.rootElement;
      String attr(String name) => root.getAttribute(name) ?? '';
      final uid = attr('uid');
      final rawFields = <String, String>{
        'name': attr('name'),
        'gender': attr('gender'),
        'yob': attr('yob').isNotEmpty ? attr('yob') : attr('dob'),
        'address_co': attr('co'),
        'house': attr('house'),
        'street': attr('street').isNotEmpty ? attr('street') : attr('loc'),
        'district': attr('dist'),
        'state': attr('state'),
        'pincode': attr('pc'),
        'uid_last4': uid.length >= 4 ? uid.substring(uid.length - 4) : '',
      };
      final fields = <String, String>{};
      rawFields.forEach((k, v) {
        if (v.isNotEmpty) fields[kFieldKeyMap[k]!] = v;
      });
      return AadhaarQrResult(
        qrGeneration: 'OLD_XML',
        signatureStatus: 'STRUCTURE_ONLY',
        fields: fields,
        noteKey: 'note_old_xml',
      );
    } catch (_) {
      // fall through to UNKNOWN below
    }
  }

  // --- Case 3: Secure QR - numeric string, zlib-compressed binary ---
  if (RegExp(r'^\d+$').hasMatch(raw)) {
    try {
      final num = BigInt.parse(raw);
      var bytes = _bigIntToBytes(num);
      final decompressed = zlib.decode(bytes);
      final parts = _splitBytes(decompressed, 0xFF);
      final textParts = parts.map((p) => utf8.decode(p, allowMalformed: true)).toList();

      const labels = [
        'ref_id', 'name', 'dob', 'gender', 'co', 'district', 'landmark',
        'house', 'location', 'pincode', 'post_office', 'state', 'street',
        'subdistrict', 'vtc',
      ];
      final rawFields = <String, String>{};
      for (var i = 0; i < labels.length && i < textParts.length; i++) {
        rawFields[labels[i]] = textParts[i];
      }

      const keyMap = {
        'name': 'field_name', 'dob': 'field_dob', 'gender': 'field_gender',
        'co': 'field_address_co', 'district': 'field_district',
        'house': 'field_house', 'pincode': 'field_pincode',
        'state': 'field_state', 'street': 'field_street',
      };
      final fields = <String, String>{};
      rawFields.forEach((k, v) {
        if (v.isNotEmpty && keyMap.containsKey(k)) fields[keyMap[k]!] = v;
      });

      return AadhaarQrResult(
        qrGeneration: 'SECURE_QR',
        signatureStatus: 'STRUCTURE_ONLY',
        fields: fields,
        noteKey: 'note_secure_qr_ok',
      );
    } catch (_) {
      return AadhaarQrResult(
        qrGeneration: 'SECURE_QR',
        signatureStatus: 'NOT_CHECKED',
        fields: {},
        noteKey: 'note_secure_qr_fail',
      );
    }
  }

  return AadhaarQrResult(
    qrGeneration: 'UNKNOWN',
    signatureStatus: 'NOT_CHECKED',
    fields: {'raw': raw.length > 200 ? raw.substring(0, 200) : raw},
    noteKey: 'note_unknown_qr',
  );
}

List<int> _bigIntToBytes(BigInt number) {
  // Big-endian byte representation, matching Python's int.to_bytes(...,
  // byteorder='big') used in the reference implementation.
  if (number == BigInt.zero) return [0];
  var hex = number.toRadixString(16);
  if (hex.length % 2 != 0) hex = '0$hex';
  final bytes = <int>[];
  for (var i = 0; i < hex.length; i += 2) {
    bytes.add(int.parse(hex.substring(i, i + 2), radix: 16));
  }
  return bytes;
}

List<List<int>> _splitBytes(List<int> data, int separator) {
  final parts = <List<int>>[];
  var current = <int>[];
  for (final b in data) {
    if (b == separator) {
      parts.add(current);
      current = [];
    } else {
      current.add(b);
    }
  }
  parts.add(current);
  return parts;
}
