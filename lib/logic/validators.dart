// Format / checksum level validators - ported from Python
// `modules/validators.py`.
//
// HONESTY NOTE: None of these validators call an official government API
// (NSDL/Protean for PAN, Parivahan for DL, NVSP for Voter ID) - those need
// paid/partnered API access an individual developer cannot get.
// What we CAN do reliably offline:
//   - Confirm the document number matches the official format.
//   - Run the real published checksum algorithm where one exists
//     (Passport MRZ has a public ICAO 9303 checksum - PAN/Voter ID/DL do
//     not have any public checksum digit, only a format pattern).
//   - Cross check OCR-extracted expiry date vs today.
// A pass here means "format is consistent with a genuine document" - it
// is NOT proof the document is genuine. Statuses use PATTERN CHECK,
// never VERIFIED, to avoid giving false confidence to CSC operators.

class ValidatorResult {
  final String status; // VALID_PATTERN | SUSPECT | REVIEW
  final String detailKey;
  final Map<String, String> params;

  ValidatorResult(this.status, this.detailKey, [this.params = const {}]);
}

ValidatorResult validatePan(String? panNumber) {
  final pan = (panNumber ?? '').toUpperCase().trim();
  if (!RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$').hasMatch(pan)) {
    return ValidatorResult('SUSPECT', 'pan_format_bad');
  }
  const fourthCharMap = {
    'P': 'Individual', 'C': 'Company', 'H': 'HUF', 'A': 'AOP',
    'B': 'BOI', 'G': 'Government', 'J': 'Artificial Judicial Person',
    'L': 'Local Authority', 'F': 'Firm/LLP', 'T': 'Trust',
  };
  final holderType = fourthCharMap[pan[3]] ?? 'Unknown';
  return ValidatorResult('VALID_PATTERN', 'pan_format_ok', {'holder_type': holderType});
}

ValidatorResult validateVoterId(String? epicNumber) {
  final epic = (epicNumber ?? '').toUpperCase().trim().replaceAll(' ', '');
  if (RegExp(r'^[A-Z]{3}[0-9]{7}$').hasMatch(epic)) {
    return ValidatorResult('VALID_PATTERN', 'voter_ok');
  }
  if (RegExp(r'^[A-Z]{3}[0-9]{6}$').hasMatch(epic)) {
    return ValidatorResult('REVIEW', 'voter_legacy');
  }
  return ValidatorResult('SUSPECT', 'voter_bad');
}

ValidatorResult validateDrivingLicense(String? dlNumber) {
  final dl = (dlNumber ?? '').toUpperCase().trim().replaceAll(' ', '').replaceAll('-', '');
  if (RegExp(r'^[A-Z]{2}[0-9]{13}$').hasMatch(dl)) {
    return ValidatorResult('VALID_PATTERN', 'dl_ok');
  }
  return ValidatorResult('REVIEW', 'dl_review');
}

ValidatorResult validateRationCard(String? cardNumber) {
  final card = (cardNumber ?? '').trim();
  if (card.isNotEmpty && card.length >= 6) {
    return ValidatorResult('REVIEW', 'ration_review');
  }
  return ValidatorResult('REVIEW', 'ration_unclear');
}

/// Tamil Nadu Community/Nativity Certificates (issued via TN e-Sevai /
/// e-District, Tahsildar's office) have no publicly documented national
/// checksum or fixed format - application/certificate numbers vary by
/// district and issuing software version. We can only confirm a
/// plausible-looking number was read; real confirmation should go
/// through the QR verification link (if present) or the Taluk office.
ValidatorResult validateCommunityNativity(String? certNumber) {
  final cert = (certNumber ?? '').trim();
  final digitsOnly = cert.replaceAll(RegExp(r'\D'), '');
  if (cert.isNotEmpty && digitsOnly.length >= 8) {
    return ValidatorResult('REVIEW', 'community_nativity_review');
  }
  return ValidatorResult('REVIEW', 'community_nativity_unclear');
}

/// TN birth certificates (CRSTN / Chennai GCC) have no public checksum
/// either - the registration number format (B-YYYY:DD-NNNNN-NNNNNN) is
/// consistent but not self-verifying. Real confirmation should go through
/// the QR verification link, which we can also cross-check locally: the
/// QR URL itself embeds the registration number as a query parameter -
/// see url_qr_parser.dart. Verified working against a real TN birth
/// certificate.
ValidatorResult validateBirthCert(String? regNumber) {
  final reg = (regNumber ?? '').trim();
  final digitsOnly = reg.replaceAll(RegExp(r'\D'), '');
  if (reg.isNotEmpty && digitsOnly.length >= 8) {
    return ValidatorResult('REVIEW', 'birth_cert_review');
  }
  return ValidatorResult('REVIEW', 'birth_cert_unclear');
}

/// ICAO 9303 MRZ check-digit algorithm (publicly documented standard).
int _mrzCheckDigit(String data) {
  const weights = [7, 3, 1];
  var total = 0;
  for (var i = 0; i < data.length; i++) {
    final ch = data[i];
    int val;
    if (RegExp(r'[0-9]').hasMatch(ch)) {
      val = int.parse(ch);
    } else if (ch == '<') {
      val = 0;
    } else if (RegExp(r'[A-Za-z]').hasMatch(ch)) {
      val = ch.codeUnitAt(0) - 55;
    } else {
      val = 0;
    }
    total += val * weights[i % 3];
  }
  return total % 10;
}

ValidatorResult validatePassportMrz(String? mrzLine2) {
  final mrz = (mrzLine2 ?? '').toUpperCase().trim();
  if (mrz.length < 10) {
    return ValidatorResult('REVIEW', 'mrz_unclear');
  }
  final passportNo = mrz.substring(0, 9).replaceAll('<', '');
  final checkDigit = mrz.length > 9 ? mrz[9] : null;

  if (checkDigit == null || !RegExp(r'[0-9]').hasMatch(checkDigit)) {
    return ValidatorResult('REVIEW', 'mrz_checkdigit_unclear');
  }

  final computed = _mrzCheckDigit(mrz.substring(0, 9));
  if (computed == int.parse(checkDigit)) {
    return ValidatorResult('VALID_PATTERN', 'mrz_ok', {'passport_no': passportNo});
  }
  return ValidatorResult('SUSPECT', 'mrz_mismatch');
}

typedef ValidatorFn = ValidatorResult Function(String?);

final Map<String, ValidatorFn> kValidators = {
  'PAN': validatePan,
  'VOTER_ID': validateVoterId,
  'DRIVING_LICENSE': validateDrivingLicense,
  'RATION_CARD': validateRationCard,
  'COMMUNITY_NATIVITY': validateCommunityNativity,
  'BIRTH_CERT': validateBirthCert,
};
