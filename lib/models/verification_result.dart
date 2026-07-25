// Data models for a document verification result - mirrors the `result`
// dict structure used throughout the Python `main.py`.

import 'package:flutter/material.dart';

class DocType {
  final String key; // e.g. 'AADHAAR'
  final String icon; // short badge text, e.g. 'ID'
  final Color color;

  const DocType(this.key, this.icon, this.color);
}

/// Supermarket-app style bright category colours, one per document type -
/// same palette as the desktop build's sidebar tabs.
const List<DocType> kDocTypes = [
  DocType('AADHAAR', 'ID', Color(0xFF2342A0)),
  DocType('PAN', 'PAN', Color(0xFF7B2FA0)),
  DocType('VOTER_ID', 'VID', Color(0xFF0E8F73)),
  DocType('PASSPORT', 'PPT', Color(0xFFCC6B14)),
  DocType('DRIVING_LICENSE', 'DL', Color(0xFF1E6FCC)),
  DocType('RATION_CARD', 'RC', Color(0xFFB58A0A)),
  DocType('BIRTH_CERT', 'BC', Color(0xFF1F8F55)),
  DocType('COMMUNITY_NATIVITY', 'CNC', Color(0xFF8A37B0)),
];

const Map<String, Color> kStatusColors = {
  'VERIFIED': Color(0xFF1FB673),
  'VALID_PATTERN': Color(0xFF3B82F6),
  'SUSPECT': Color(0xFFE5484D),
  'REVIEW': Color(0xFFF5A524),
  'MATCH': Color(0xFF1FB673),
  'PARTIAL': Color(0xFFF5A524),
  'MISMATCH': Color(0xFFE5484D),
  'CURRENT': Color(0xFF1FB673),
  'EXPIRED': Color(0xFFE5484D),
  'NA': Color(0xFF8C8C8C),
};

class VerificationResult {
  String docType = '';
  String qrGeneration = 'NONE';
  String signatureStatus = 'NOT_CHECKED';
  String overallStatus = 'REVIEW';
  String expiryStatus = 'NA';
  String? expiryDate;
  Map<String, String> fields = {};
  String noteKey = '';
  Map<String, String> noteParams = {};
}
