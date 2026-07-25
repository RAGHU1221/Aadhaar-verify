// Bilingual (Tamil + English) UI string dictionary - ported 1:1 from the
// proven Python `modules/i18n.py` (same 124 keys, generated automatically
// from that file to avoid transcription errors in the Tamil text).
//
// Usage:
//   t('upload_btn')            -> 'Upload Document' (English)
//   t('upload_btn', lang: 'ta') -> 'ஆவணத்தை பதிவேற்று'
//   bi('upload_btn')            -> 'Upload Document / ஆவணத்தை பதிவேற்று'
//   biStack('upload_btn')       -> 'Upload Document\nஆவணத்தை பதிவேற்று'
//   t('mrz_ok', params: {'passport_no': 'L898902C'})

// GENERATED from Python modules/i18n.py - do not hand-edit the map contents,
// regenerate from the Python source of truth if strings change.
final Map<String, Map<String, String>> kStrings = {
  'app_title': {'en': 'AADHAAR VERIFICATION DESK', 'ta': 'ஆதார் சரிபார்ப்பு மேசை'},
  'app_subtitle': {'en': 'CSC / Aadhaar Seva Kendra - Document Scrutiny Register', 'ta': 'சி.எஸ்.சி / ஆதார் சேவா கேந்திரம் - ஆவண சோதனைப் பதிவேடு'},
  'sidebar_heading': {'en': 'DOCUMENT REGISTER', 'ta': 'ஆவணப் பதிவேடு'},
  'console_title': {'en': 'Document Verification Console', 'ta': 'ஆவண சரிபார்ப்பு பலகை'},
  'upload_btn': {'en': 'Upload Document', 'ta': 'ஆவணத்தை பதிவேற்று'},
  'scan_btn': {'en': 'Scan Document', 'ta': 'ஆவணத்தை ஸ்கேன் செய்'},
  'no_scanner_found': {'en': 'No scanner found. Connect a scanner (or check its driver is installed) and try again.', 'ta': 'ஸ்கேனர் கிடைக்கவில்லை. ஸ்கேனரை இணைத்து (driver install ஆகி இருக்கானு பாருங்க) மீண்டும் முயற்சிக்கவும்.'},
  'select_scanner_title': {'en': 'Select scanner', 'ta': 'ஸ்கேனரை தேர்வு செய்யவும்'},
  'select_scanner_question': {'en': 'Choose which scanner to use:', 'ta': 'எந்த ஸ்கேனரை பயன்படுத்தணும்?'},
  'cancel_scan_selection': {'en': 'Cancel', 'ta': 'ரத்து செய்'},
  'scanning_in_progress': {'en': 'Opening scanner...', 'ta': 'ஸ்கேனர் திறக்கப்படுகிறது...'},
  'scan_failed': {'en': 'Scanning failed or was cancelled.', 'ta': 'ஸ்கேன் தோல்வியடைந்தது அல்லது ரத்து செய்யப்பட்டது.'},
  'scan_captured': {'en': 'Document scanned successfully.', 'ta': 'ஆவணம் வெற்றிகரமாக ஸ்கேன் ஆனது.'},
  'scan_next_page_title': {'en': 'Scan next page?', 'ta': 'அடுத்த பக்கத்தை ஸ்கேன் செய்யவா?'},
  'scan_next_page_question': {'en': 'Page scanned. Is there another page to scan\nfor this document?', 'ta': 'பக்கம் ஸ்கேன் ஆனது. இந்த ஆவணத்திற்கு\nமேலும் ஒரு பக்கம் இருக்கிறதா?'},
  'scan_next_page_yes': {'en': 'Yes, scan next page', 'ta': 'ஆம், அடுத்த பக்கம்'},
  'scan_next_page_no': {'en': 'No, finish', 'ta': 'இல்லை, முடிக்கவும்'},
  'converting_pdf': {'en': 'Converting PDF pages...', 'ta': 'PDF பக்கங்கள் மாற்றப்படுகிறது...'},
  'pdf_convert_failed': {'en': 'Could not read this PDF - it may be corrupted or password-protected.', 'ta': 'இந்த PDF-ஐ படிக்க முடியவில்லை - அது பாதிக்கப்பட்டதாகவோ, கடவுச்சொல் பாதுகாப்புடனோ இருக்கலாம்.'},
  'tamil_font_missing': {'en': 'No Tamil font was found installed on this PC, so some Tamil text may look wrong. To fix: open the app\'s \'assets\\fonts\' folder, double-click NotoSansTamil-Regular.ttf and NotoSansTamil-Bold.ttf, and click Install on each (one-time).', 'ta': 'இந்த கணினியில் தமிழ் எழுத்துரு install ஆகவில்லை, அதனால் சில தமிழ் எழுத்துக்கள் தவறாக தெரியலாம். சரிசெய்ய: \'assets\\fonts\' folder-ஐ திறந்து NotoSansTamil-Regular.ttf மற்றும் NotoSansTamil-Bold.ttf-ஐ double-click செய்து Install அழுத்தவும்.'},
  'verify_btn': {'en': 'Verify', 'ta': 'சரிபார்'},
  'export_btn': {'en': 'Export PDF Report', 'ta': 'PDF அறிக்கை பதிவிறக்கு'},
  'no_file': {'en': 'No file selected', 'ta': 'கோப்பு தேர்வு செய்யவில்லை'},
  'placeholder': {'en': 'Upload a scanned document and click Verify\nto see the scrutiny report here.', 'ta': 'ஸ்கேன் செய்த ஆவணத்தை பதிவேற்றி Verify\nபொத்தானை அழுத்தவும்.'},
  'scanning': {'en': 'Scanning QR + running OCR...', 'ta': 'QR ஸ்கேன் + OCR நடைபெறுகிறது...'},
  'done': {'en': 'Done.', 'ta': 'முடிந்தது.'},
  'footer_note': {'en': 'Offline pattern/QR check only.\nNot a substitute for official\nUIDAI/NSDL/Parivahan/NVSP\nverification.', 'ta': 'இது ஆஃப்லைன் QR/முறை சோதனை மட்டுமே.\nஉத்தியோகபூர்வ UIDAI/NSDL/Parivahan/\nNVSP சரிபார்ப்புக்கு மாற்றாக இதை\nபயன்படுத்த வேண்டாம்.'},
  'extracted_details': {'en': 'EXTRACTED DETAILS', 'ta': 'பெறப்பட்ட விவரங்கள்'},
  'qr_sig_line': {'en': 'QR generation: {qr}   |   Signature status: {sig}', 'ta': 'QR வகை: {qr}   |   கையொப்ப நிலை: {sig}'},
  'expiry_line': {'en': 'Expiry check: {status}', 'ta': 'காலாவதி சோதனை: {status}'},
  'expiry_date_suffix': {'en': ' (date on doc: {date})', 'ta': ' (ஆவணத்தில் உள்ள தேதி: {date})'},
  'exported_title': {'en': 'Exported', 'ta': 'ஏற்றுமதி ஆனது'},
  'exported_msg': {'en': 'Report saved:\n{path}', 'ta': 'அறிக்கை சேமிக்கப்பட்டது:\n{path}'},
  'cross_check_heading': {'en': 'Cross-Check Declared Details', 'ta': 'அறிவிக்கப்பட்ட விவரங்களை ஒப்பிடு'},
  'label_declared_name': {'en': 'Declared Name', 'ta': 'அறிவிக்கப்பட்ட பெயர்'},
  'label_declared_year': {'en': 'Declared DOB/Year', 'ta': 'அறிவிக்கப்பட்ட பிறந்த ஆண்டு'},
  'label_declared_parent': {'en': 'Declared Parent/Guardian', 'ta': 'அறிவிக்கப்பட்ட பெற்றோர்/பாதுகாவலர்'},
  'compare_btn': {'en': 'Compare', 'ta': 'ஒப்பிடு'},
  'open_link_btn': {'en': 'Open Verify Link', 'ta': 'சரிபார்ப்பு லிங்க் திற'},
  'match_MATCH': {'en': 'MATCH', 'ta': 'பொருந்துகிறது'},
  'match_PARTIAL': {'en': 'PARTIAL MATCH', 'ta': 'பகுதி பொருத்தம்'},
  'match_MISMATCH': {'en': 'MISMATCH', 'ta': 'பொருந்தவில்லை'},
  'match_REVIEW': {'en': 'N/A', 'ta': 'இல்லை'},
  'match_name_row': {'en': 'Name', 'ta': 'பெயர்'},
  'match_year_row': {'en': 'DOB/Year', 'ta': 'பிறந்த ஆண்டு'},
  'match_parent_row': {'en': 'Parent/Guardian', 'ta': 'பெற்றோர்/பாதுகாவலர்'},
  'no_qr_fields_for_compare': {'en': 'No name/DOB/parent fields were extracted from this document to compare against.', 'ta': 'ஒப்பிட இந்த ஆவணத்தில் இருந்து பெயர்/பிறந்த ஆண்டு/பெற்றோர் விவரங்கள் எடுக்கப்படவில்லை.'},
  'link_opened': {'en': 'Verification link opened in your browser.', 'ta': 'சரிபார்ப்பு லிங்க் உங்கள் browser-ல் திறக்கப்பட்டது.'},
  'doc_AADHAAR': {'en': 'Aadhaar Card', 'ta': 'ஆதார் அட்டை'},
  'doc_PAN': {'en': 'PAN Card', 'ta': 'பான் அட்டை'},
  'doc_VOTER_ID': {'en': 'Voter ID (EPIC)', 'ta': 'வாக்காளர் அடையாள அட்டை'},
  'doc_PASSPORT': {'en': 'Passport', 'ta': 'பாஸ்போர்ட்'},
  'doc_DRIVING_LICENSE': {'en': 'Driving Licence', 'ta': 'ஓட்டுநர் உரிமம்'},
  'doc_RATION_CARD': {'en': 'Ration Card', 'ta': 'குடும்ப அட்டை'},
  'doc_BIRTH_CERT': {'en': 'Birth Certificate', 'ta': 'பிறப்பு சான்றிதழ்'},
  'doc_COMMUNITY_NATIVITY': {'en': 'Community / Nativity Certificate', 'ta': 'சமுதாய / பூர்வீக சான்றிதழ்'},
  'status_VERIFIED': {'en': 'VERIFIED', 'ta': 'சரிபார்க்கப்பட்டது'},
  'status_VERIFIED_sub': {'en': 'STRUCTURE OK', 'ta': 'கட்டமைப்பு சரி'},
  'status_VALID_PATTERN': {'en': 'FORMAT OK', 'ta': 'வடிவம் சரி'},
  'status_VALID_PATTERN_sub': {'en': 'PATTERN CHECK', 'ta': 'முறை சோதனை'},
  'status_SUSPECT': {'en': 'SUSPECT', 'ta': 'சந்தேகம்'},
  'status_SUSPECT_sub': {'en': 'LIKELY FAKE', 'ta': 'போலியாக இருக்கலாம்'},
  'status_REVIEW': {'en': 'REVIEW', 'ta': 'மறு பரிசீலனை'},
  'status_REVIEW_sub': {'en': 'MANUAL CHECK', 'ta': 'கைமுறை சரிபார்ப்பு'},
  'status_EXPIRED': {'en': 'EXPIRED', 'ta': 'காலாவதியானது'},
  'status_CURRENT': {'en': 'CURRENT', 'ta': 'செல்லுபடியாகும்'},
  'field_name': {'en': 'Name', 'ta': 'பெயர்'},
  'field_gender': {'en': 'Gender', 'ta': 'பாலினம்'},
  'field_yob': {'en': 'Year of Birth', 'ta': 'பிறந்த ஆண்டு'},
  'field_dob': {'en': 'Date of Birth', 'ta': 'பிறந்த தேதி'},
  'field_address_co': {'en': 'Care of', 'ta': 'பராமரிப்பாளர்'},
  'field_house': {'en': 'House', 'ta': 'வீட்டு எண்'},
  'field_street': {'en': 'Street', 'ta': 'தெரு'},
  'field_district': {'en': 'District', 'ta': 'மாவட்டம்'},
  'field_state': {'en': 'State', 'ta': 'மாநிலம்'},
  'field_pincode': {'en': 'Pincode', 'ta': 'அஞ்சல் குறியீடு'},
  'field_uid_last4': {'en': 'UID (last 4)', 'ta': 'UID (கடைசி 4)'},
  'field_detected_number': {'en': 'Detected Number', 'ta': 'கண்டறியப்பட்ட எண்'},
  'field_qr_raw': {'en': 'QR data (raw)', 'ta': 'QR தரவு (மூலம்)'},
  'field_ocr_excerpt': {'en': 'OCR excerpt', 'ta': 'OCR பகுதி'},
  'field_digilocker_verify_url': {'en': 'DigiLocker Verify URL', 'ta': 'டிஜிலாக்கர் சரிபார்ப்பு URL'},
  'field_verify_url': {'en': 'Verification URL (from QR)', 'ta': 'சரிபார்ப்பு URL (QR-ல் இருந்து)'},
  'field_certificate_no': {'en': 'Certificate / Application No', 'ta': 'சான்றிதழ் / விண்ணப்ப எண்'},
  'field_community': {'en': 'Community', 'ta': 'சமுதாயம்'},
  'field_father_name': {'en': 'Father/Guardian Name', 'ta': 'தந்தை/பாதுகாவலர் பெயர்'},
  'field_taluk': {'en': 'Taluk', 'ta': 'தாலுகா'},
  'field_date_of_issue': {'en': 'Date of Issue', 'ta': 'வழங்கிய தேதி'},
  'field_service_applied': {'en': 'Service Applied', 'ta': 'விண்ணப்பித்த சேவை'},
  'field_address': {'en': 'Address', 'ta': 'முகவரி'},
  'note_no_qr_aadhaar': {'en': 'No QR code detected on this Aadhaar document. Genuine Aadhaar letters/PVC cards always carry a QR. Re-scan at higher resolution before concluding it\'s fake.', 'ta': 'இந்த ஆதார் ஆவணத்தில் QR குறியீடு இல்லை. உண்மையான ஆதார் கடிதம்/PVC அட்டையில் எப்போதும் QR இருக்கும். இது போலி என முடிவெடுப்பதற்கு முன் அதிக தெளிவுத்திறனில் மீண்டும் ஸ்கேன் செய்யவும்.'},
  'note_old_xml': {'en': 'Old-format Aadhaar QR (pre-2019). Fields parsed directly from XML. This confirms the QR is well-formed Aadhaar data, but full UIDAI signature check is not performed.', 'ta': 'பழைய வடிவ ஆதார் QR (2019க்கு முன்). XML-லிருந்து நேரடியாக விவரங்கள் எடுக்கப்பட்டன. இது QR சரியான ஆதார் தரவு என உறுதி செய்கிறது, ஆனால் முழுமையான UIDAI கையொப்ப சோதனை செய்யப்படவில்லை.'},
  'note_secure_qr_ok': {'en': 'Secure QR decompressed successfully - demographic fields extracted. UIDAI\'s digital signature has NOT been cryptographically verified (needs UIDAI\'s public certificate). Treat this as \'structure looks genuine\', not \'signature confirmed\'.', 'ta': 'செக்யூர் QR வெற்றிகரமாக டீகம்ப்ரெஸ் செய்யப்பட்டது - விவரங்கள் பிரித்தெடுக்கப்பட்டன. UIDAI-ன் டிஜிட்டல் கையொப்பம் இன்னும் சரிபார்க்கப்படவில்லை (UIDAI-ன் பப்ளிக் சான்றிதழ் தேவை). இதை \'கட்டமைப்பு சரியாக தெரிகிறது\' என எடுத்துக் கொள்ளுங்கள், \'கையொப்பம் உறுதி\' என அல்ல.'},
  'note_secure_qr_fail': {'en': 'Numeric Secure QR detected but could not be decompressed with standard zlib - the QR image may be low quality, cropped, or partially unreadable. Re-scan at higher resolution.', 'ta': 'செக்யூர் QR கண்டறியப்பட்டது ஆனால் டீகம்ப்ரெஸ் செய்ய முடியவில்லை - QR படம் தெளிவு குறைவாகவோ, வெட்டப்பட்டதாகவோ இருக்கலாம். அதிக தெளிவுத்திறனில் மீண்டும் ஸ்கேன் செய்யவும்.'},
  'note_digilocker': {'en': 'DigiLocker QR detected. Open this URL (or scan with the DigiLocker app) to confirm the document against the issuing department\'s record. This app does not auto-verify DigiLocker URLs to avoid making unverified network calls.', 'ta': 'டிஜிலாக்கர் QR கண்டறியப்பட்டது. இந்த URL-ஐ திற (அல்லது டிஜிலாக்கர் ஆப் மூலம் ஸ்கேன் செய்யவும்) வெளியிட்ட துறையின் பதிவுடன் உறுதி செய்ய. இந்த ஆப் டிஜிலாக்கர் URL-களை தானாக சரிபார்க்காது.'},
  'note_unknown_qr': {'en': 'QR found but format not recognised as Aadhaar/DigiLocker.', 'ta': 'QR கிடைத்தது ஆனால் அது ஆதார்/டிஜிலாக்கர் வடிவமாக அடையாளம் காணப்படவில்லை.'},
  'note_no_validator': {'en': 'No automated format validator available for this document type yet.', 'ta': 'இந்த ஆவண வகைக்கு தானியங்கி வடிவ சரிபார்ப்பு இன்னும் இல்லை.'},
  'pan_format_ok': {'en': 'Format OK. 4th letter indicates holder type: {holder_type}.', 'ta': 'வடிவம் சரி. 4வது எழுத்து வைத்திருப்பவர் வகையை குறிக்கிறது: {holder_type}.'},
  'pan_format_bad': {'en': 'PAN does not match official format AAAAA9999A', 'ta': 'PAN அதிகாரப்பூர்வ வடிவமான AAAAA9999A உடன் பொருந்தவில்லை'},
  'voter_ok': {'en': 'Format OK (3 letters + 7 digits).', 'ta': 'வடிவம் சரி (3 எழுத்துகள் + 7 எண்கள்).'},
  'voter_legacy': {'en': '6-digit legacy EPIC format - verify manually on NVSP portal.', 'ta': '6-இலக்க பழைய EPIC வடிவம் - NVSP போர்ட்டலில் கைமுறையாக சரிபார்க்கவும்.'},
  'voter_bad': {'en': 'EPIC number does not match known Voter ID formats.', 'ta': 'EPIC எண் அறியப்பட்ட வாக்காளர் அடையாள வடிவங்களுடன் பொருந்தவில்லை.'},
  'dl_ok': {'en': 'Format OK (state+RTO+13 digit number).', 'ta': 'வடிவம் சரி (மாநிலம்+RTO+13 இலக்க எண்).'},
  'dl_review': {'en': 'DL format not recognised - state formats vary, verify on Parivahan portal.', 'ta': 'DL வடிவம் அடையாளம் காணப்படவில்லை - Parivahan போர்ட்டலில் சரிபார்க்கவும்.'},
  'ration_review': {'en': 'Ration card numbers are state-specific - manual cross-check advised.', 'ta': 'குடும்ப அட்டை எண்கள் மாநில அடிப்படையிலானவை - கைமுறையாக சரிபார்க்கவும்.'},
  'ration_unclear': {'en': 'Could not read a clear ration card number - manual check needed.', 'ta': 'குடும்ப அட்டை எண் தெளிவாக படிக்க முடியவில்லை - கைமுறை சோதனை தேவை.'},
  'community_nativity_review': {'en': 'Tamil Nadu Community/Nativity Certificates have no national checksum - if the QR contains a tnesevai.tn.gov.in / e-District link, use \'Open Verify Link\' to confirm against the Revenue Department\'s own record. Otherwise cross-check manually at the Taluk office.', 'ta': 'தமிழ்நாடு சமுதாய/பூர்வீக சான்றிதழ்களுக்கு தேசிய செக்சம் கிடையாது - QR-ல் tnesevai.tn.gov.in / e-District லிங்க் இருந்தால், \'Open Verify Link\' பயன்படுத்தி வருவாய் துறையின் பதிவுடன் உறுதி செய்யவும். இல்லையெனில் தாலுகா அலுவலகத்தில் கைமுறையாக சரிபார்க்கவும்.'},
  'community_nativity_unclear': {'en': 'Could not read a clear certificate/application number - manual check needed.', 'ta': 'சான்றிதழ்/விண்ணப்ப எண் தெளிவாக படிக்க முடியவில்லை - கைமுறை சோதனை தேவை.'},
  'structured_qr_match': {'en': 'QR code contains structured data with Application No. {qr_no}, which MATCHES the number printed on the document. This QR content is much harder to forge than a plain printed number, so this is a stronger signal - but still cross-check the printed name/address against the QR fields below.', 'ta': 'QR குறியீட்டில் {qr_no} விண்ணப்ப எண் இருக்கிறது, இது ஆவணத்தில் அச்சிடப்பட்ட எண்ணுடன் பொருந்துகிறது. இந்த QR உள்ளடக்கத்தை போலியாக்குவது கடினம், எனவே இது ஒரு வலுவான அறிகுறி - ஆனாலும் கீழே உள்ள QR விவரங்களுடன் பெயர்/முகவரியை ஒப்பிட்டு பாருங்கள்.'},
  'structured_qr_mismatch': {'en': 'QR code contains Application No. {qr_no}, which does NOT match the number printed/read on the document ({printed_no}). This is a strong signal of tampering - flag for manual review before accepting.', 'ta': 'QR குறியீட்டில் உள்ள விண்ணப்ப எண் {qr_no}, ஆவணத்தில் அச்சிடப்பட்ட எண்ணுடன் ({printed_no}) பொருந்தவில்லை. இது ஆவணம் மாற்றப்பட்டிருக்கலாம் என்பதற்கான வலுவான அறிகுறி - ஏற்கும் முன் கைமுறையாக சரிபார்க்கவும்.'},
  'mrz_unclear': {'en': 'MRZ line not clearly read - rescan the passport photo page.', 'ta': 'MRZ வரி தெளிவாக படிக்கப்படவில்லை - பாஸ்போர்ட் பக்கத்தை மீண்டும் ஸ்கேன் செய்யவும்.'},
  'mrz_checkdigit_unclear': {'en': 'Could not isolate MRZ check digit - rescan needed.', 'ta': 'MRZ சரிபார்ப்பு இலக்கத்தை பிரிக்க முடியவில்லை - மீண்டும் ஸ்கேன் தேவை.'},
  'mrz_ok': {'en': 'MRZ checksum verified for passport no. {passport_no}.', 'ta': 'பாஸ்போர்ட் எண் {passport_no}-க்கான MRZ சரிபார்ப்பு வெற்றி.'},
  'mrz_mismatch': {'en': 'MRZ checksum MISMATCH - document may be altered or misread. Rescan to confirm before flagging.', 'ta': 'MRZ சரிபார்ப்பு பொருந்தவில்லை - ஆவணம் மாற்றப்பட்டிருக்கலாம் அல்லது தவறாக படிக்கப்பட்டது. உறுதி செய்ய மீண்டும் ஸ்கேன் செய்யவும்.'},
  'pdf_title': {'en': 'DOCUMENT VERIFICATION REGISTER', 'ta': 'ஆவண சரிபார்ப்பு பதிவேடு'},
  'pdf_generated': {'en': 'Generated', 'ta': 'உருவாக்கப்பட்டது'},
  'pdf_qr_sig_heading': {'en': 'QR / Signature Check', 'ta': 'QR / கையொப்ப சோதனை'},
  'pdf_validity_heading': {'en': 'Validity / Expiry', 'ta': 'செல்லுபடி / காலாவதி'},
  'pdf_extracted_heading': {'en': 'Extracted Details', 'ta': 'பெறப்பட்ட விவரங்கள்'},
  'pdf_note_heading': {'en': 'Verification note', 'ta': 'சரிபார்ப்பு குறிப்பு'},
  'pdf_footer': {'en': 'Verified by: {who} | This report is an offline pattern/structure check and is not a substitute for official UIDAI/NSDL/Parivahan/NVSP verification.', 'ta': 'சரிபார்த்தவர்: {who} | இந்த அறிக்கை ஆஃப்லைன் முறை/கட்டமைப்பு சோதனை மட்டுமே, உத்தியோகபூர்வ UIDAI/NSDL/Parivahan/NVSP சரிபார்ப்புக்கு மாற்றல்ல.'},
  'pdf_status_VERIFIED': {'en': 'VERIFIED - QR / Digital Signature Structure Confirmed', 'ta': 'சரிபார்க்கப்பட்டது - QR / டிஜிட்டல் கையொப்ப கட்டமைப்பு உறுதி'},
  'pdf_status_VALID_PATTERN': {'en': 'FORMAT VALID - Pattern / Checksum Check Passed', 'ta': 'வடிவம் சரி - முறை / செக்சம் சோதனை தேர்ச்சி'},
  'pdf_status_SUSPECT': {'en': 'LIKELY FAKE / MISMATCH DETECTED', 'ta': 'போலியாக இருக்கலாம் / பொருத்தமின்மை'},
  'pdf_status_REVIEW': {'en': 'MANUAL REVIEW NEEDED', 'ta': 'கைமுறை மறு பரிசீலனை தேவை'},
};
String _formatTemplate(String template, Map<String, String>? params) {
  if (params == null || params.isEmpty) return template;
  var result = template;
  params.forEach((k, v) {
    result = result.replaceAll('{$k}', v);
  });
  return result;
}

/// Looks up a bilingual string and formats it. Falls back to the raw key
/// if not found (mirrors Python's `i18n.t`).
String t(String key, {String lang = 'en', Map<String, String>? params}) {
  final entry = kStrings[key];
  if (entry == null) return key;
  final template = entry[lang] ?? entry['en'] ?? key;
  return _formatTemplate(template, params);
}

/// Returns 'English / தமிழ்' combined single-line string.
String bi(String key, {Map<String, String>? params}) {
  final entry = kStrings[key];
  if (entry == null) return key;
  return '${t(key, lang: 'en', params: params)} / ${t(key, lang: 'ta', params: params)}';
}

/// Returns English on line 1, Tamil on line 2 (for multi-line labels).
String biStack(String key, {Map<String, String>? params}) {
  final entry = kStrings[key];
  if (entry == null) return key;
  return '${t(key, lang: 'en', params: params)}\n${t(key, lang: 'ta', params: params)}';
}
