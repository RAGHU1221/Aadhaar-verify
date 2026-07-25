// Parses recognised query parameters out of a verification-link QR (e.g.
// TN CRSTN birth certificate QR codes, which encode a URL like
// https://crstn.org/.../birth_cert_print_test.jsp?REG_NO=...&certificateNo=...)
// so we can cross-check the QR's embedded reference number against the
// number printed/OCR'd on the document itself - entirely offline, no
// network fetch to the government portal needed for this part.
//
// Verified against a real TN birth certificate: the QR contained
// REG_NO=B-2023:33-15958-000936, which matched the OCR'd printed
// registration number exactly.

const Map<String, String> kUrlParamMap = {
  'REG_NO': 'field_registration_no',
  'regno': 'field_registration_no',
  'reg_no': 'field_registration_no',
  'certificateNo': 'field_certificate_no',
  'certificate_no': 'field_certificate_no',
  'applicationNo': 'field_certificate_no',
  'application_no': 'field_certificate_no',
};

/// Returns a map of {i18n_field_key: value} for any recognised query
/// parameters found in the URL. Returns {} if none matched or the URL
/// couldn't be parsed.
Map<String, String> parseVerifyUrl(String url) {
  final fields = <String, String>{};
  try {
    final uri = Uri.parse(url);
    uri.queryParameters.forEach((k, v) {
      final key = kUrlParamMap[k];
      if (key != null && v.isNotEmpty) {
        fields[key] = v;
      }
    });
  } catch (_) {
    // malformed URL - just return what we have (likely empty)
  }
  return fields;
}

/// Prefers the registration number, falls back to certificate number, for
/// cross-checking against the OCR-detected document number.
String? extractReferenceNumber(Map<String, String> fields) {
  return fields['field_registration_no'] ?? fields['field_certificate_no'];
}
