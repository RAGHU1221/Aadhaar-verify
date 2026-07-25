// Generic key-value text QR parser - ported from Python
// `modules/text_qr_parser.py`.
//
// Many Indian state e-governance certificate QR codes (TN e-Sevai/
// e-District Community, Nativity, Income, and similar certificates)
// encode a plain "Label : Value" text block directly in the QR - not a
// URL. This parses that generic format into our i18n field keys so the
// operator sees proper bilingual labels instead of a wall of raw QR text.

const Map<String, String> kLabelMap = {
  'application no': 'field_certificate_no',
  'application number': 'field_certificate_no',
  'certificate no': 'field_certificate_no',
  'certificate number': 'field_certificate_no',
  'applicant name': 'field_name',
  'name': 'field_name',
  'service applied': 'field_service_applied',
  'address': 'field_address',
  'father name': 'field_father_name',
  'fathers name': 'field_father_name',
  "father's name": 'field_father_name',
  'community': 'field_community',
  'taluk': 'field_taluk',
  'district': 'field_district',
  'date of issue': 'field_date_of_issue',
};

/// Quick heuristic: does this QR payload look like our 'Label : Value'
/// text format rather than a URL, Aadhaar XML, or an opaque binary blob?
bool looksLikeKeyValueText(String rawData) {
  if (rawData.isEmpty ||
      rawData.startsWith('http://') ||
      rawData.startsWith('https://') ||
      rawData.startsWith('<')) {
    return false;
  }
  return rawData.contains(':');
}

/// Parses 'Label : Value' lines into a map of {i18n_field_key: value}.
/// Returns {} if nothing recognisable was found.
Map<String, String> parseKeyValueQr(String rawData) {
  final fields = <String, String>{};
  for (final rawLine in rawData.trim().split('\n')) {
    final line = rawLine.trim();
    if (line.isEmpty || !line.contains(':')) continue;
    final idx = line.indexOf(':');
    final label = line.substring(0, idx);
    final value = line.substring(idx + 1).trim();
    if (value.isEmpty) continue;
    final labelKey = label
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z ]'), '')
        .trim();
    final fieldKey = kLabelMap[labelKey] ?? label.trim();
    fields[fieldKey] = value;
  }
  return fields;
}

/// Pulls the certificate/application number out of parsed QR fields, if
/// present, for cross-checking against the OCR-detected number.
String? extractNumberField(Map<String, String> fields) {
  return fields['field_certificate_no'];
}
