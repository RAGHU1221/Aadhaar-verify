// Cross-check matcher - ported from Python `modules/matcher.py`.
//
// Compares applicant-declared details (typed in by the CSC operator from
// the enrollment form) against the demographic fields pulled from the
// document's QR/OCR data. Pure local text comparison - no network calls,
// no scraping of any government portal.

final RegExp _relationPrefixRe =
    RegExp(r'^(S/O|D/O|W/O|C/O|SO|DO|WO|CO)[:.]?\s*', caseSensitive: false);

String normalize(String? s) {
  if (s == null || s.isEmpty) return '';
  var out = s.toUpperCase().trim();
  out = out.replaceAll(RegExp(r'\s+'), ' ');
  return out;
}

String stripRelationPrefix(String? s) {
  return normalize(s).replaceFirst(_relationPrefixRe, '');
}

/// A Dart port of Python's difflib.SequenceMatcher(None, a, b).ratio() -
/// the Ratcliff/Obershelp algorithm: recursively find the longest
/// matching contiguous block, then recurse on the left/right remainders.
/// ratio = 2*M / (len(a)+len(b)) where M is the total matched length.
double _sequenceRatio(String a, String b) {
  if (a.isEmpty && b.isEmpty) return 1.0;
  final matches = _totalMatchingLength(a, 0, a.length, b, 0, b.length);
  return (2.0 * matches) / (a.length + b.length);
}

int _totalMatchingLength(String a, int aLo, int aHi, String b, int bLo, int bHi) {
  final match = _findLongestMatch(a, aLo, aHi, b, bLo, bHi);
  if (match == null) return 0;
  final size = match[2];
  var total = size;
  if (match[0] > aLo && match[1] > bLo) {
    total += _totalMatchingLength(a, aLo, match[0], b, bLo, match[1]);
  }
  if (match[0] + size < aHi && match[1] + size < bHi) {
    total += _totalMatchingLength(a, match[0] + size, aHi, b, match[1] + size, bHi);
  }
  return total;
}

/// Returns [aStart, bStart, size] for the longest matching contiguous
/// block of a[aLo:aHi] within b[bLo:bHi], or null if no match at all.
List<int>? _findLongestMatch(String a, int aLo, int aHi, String b, int bLo, int bHi) {
  // Map each char in b[bLo:bHi] to the list of indices where it occurs.
  final b2j = <String, List<int>>{};
  for (var j = bLo; j < bHi; j++) {
    b2j.putIfAbsent(b[j], () => []).add(j);
  }

  var bestI = aLo, bestJ = bLo, bestSize = 0;
  var j2len = <int, int>{};
  for (var i = aLo; i < aHi; i++) {
    final newJ2Len = <int, int>{};
    final positions = b2j[a[i]];
    if (positions != null) {
      for (final j in positions) {
        final k = (j2len[j - 1] ?? 0) + 1;
        newJ2Len[j] = k;
        if (k > bestSize) {
          bestI = i - k + 1;
          bestJ = j - k + 1;
          bestSize = k;
        }
      }
    }
    j2len = newJ2Len;
  }
  if (bestSize == 0) return null;
  return [bestI, bestJ, bestSize];
}

double similarity(String? a, String? b) {
  return _sequenceRatio(normalize(a), normalize(b));
}

/// Returns 'MATCH' | 'PARTIAL' | 'MISMATCH' | 'REVIEW' (REVIEW = one side empty).
String matchStatus(String? declared, String? extracted,
    {bool isParentField = false, double matchTh = 0.85, double partialTh = 0.55}) {
  if (declared == null || declared.trim().isEmpty || extracted == null || extracted.trim().isEmpty) {
    return 'REVIEW';
  }
  var a = declared, b = extracted;
  if (isParentField) {
    a = stripRelationPrefix(a);
    b = stripRelationPrefix(b);
  }
  final r = similarity(a, b);
  if (r >= matchTh) return 'MATCH';
  if (r >= partialTh) return 'PARTIAL';
  return 'MISMATCH';
}

/// Loose match on year of birth - pulls the 4-digit year out of either a
/// full DOB string or a plain year and compares.
String yearMatchStatus(String? declaredDobOrYear, String? extractedYobOrDob) {
  if (declaredDobOrYear == null || declaredDobOrYear.isEmpty ||
      extractedYobOrDob == null || extractedYobOrDob.isEmpty) {
    return 'REVIEW';
  }
  final yearRe = RegExp(r'(19|20)\d{2}');
  final y1 = yearRe.firstMatch(declaredDobOrYear);
  final y2 = yearRe.firstMatch(extractedYobOrDob);
  if (y1 == null || y2 == null) return 'REVIEW';
  return y1.group(0) == y2.group(0) ? 'MATCH' : 'MISMATCH';
}
