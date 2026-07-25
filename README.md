# 🧵 Textile Shop Billing Software (Windows .EXE)

Bilingual (Tamil + English) billing software — textile/cloth shop ku special-ah design panniyachu.
Muthal la Python program ah run pannalam, appuram indha ஒரே folder ah Windows .exe ah convert pannalam.

---

## 📁 Indha Folder la Enna Irukku

| File | Enna Panradhu |
|---|---|
| `app.py` | Main software (screens, buttons, billing logic) |
| `db.py` | Database logic (products, customers, bills save panradhu) |
| `qr_utils.py` | QR code generate panradhu + camera-la scan panradhu logic |
| `fonts/` | Tamil font files (Noto Sans Tamil) - software-oda "own" font, unga PC-ல் Tamil font இல்லைனாலும் சரியா காட்டும் |
| `.github/workflows/build-exe.yml` | GitHub Actions file - online-லேயே .exe build பண்ண (கீழே பாருங்க) |
| `requirements.txt` | Extra libraries list (QR/camera ku venum) |
| `build_exe.bat` | Ithu double-click pannina, .exe file automatic-ah create aagum |
| `README.md` | Indha instructions file |

> 🔤 **Tamil Font Fix:** முன்ன Tamil text சரியா தெரியாத problem இருந்தா, இப்போ software-க்கே சொந்தமா ஒரு Tamil font (`fonts/` folder-ல) இருக்கு. exe build ஆனாலும் இந்த font automatic-ஆ உள்ளே சேர்ந்து, unga PC-ல் Tamil font install ஆகி இருந்தாலும் இல்லைனாலும் சரியா காட்டும்.

Software first run panna, `textile_billing.db` nu oru file automatic-ah create aagum — adhula ellaa data um (products, bills, customers) save aagum. Adha delete pannaadheenga!

---

## ▶️ STEP 1: Testing pannunga (Windows PC la)

1. Python install pannunga (illainna): https://www.python.org/downloads/ 
   → Install panra pothu **"Add Python to PATH"** checkbox ah click pannunga.
2. Indha folder ah unga PC ku copy pannunga.
3. Command Prompt (cmd) open pannunga, indha folder ku pogunga:
   ```
   cd path\to\textile_billing_app
   ```
4. Extra libraries install pannunga (QR & Camera ku venum, one-time):
   ```
   pip install -r requirements.txt
   ```
5. Run pannunga:
   ```
   python app.py
   ```
6. Software open aagum — Tamil + English la buttons kaanum. Test pannunga:
   - "📦 Products" la 2-3 products add pannunga (name, design no, color, price, stock)
   - "🧾 New Bill" la oru bill create pannunga
   - "📊 Reports" la bill save aachaan check pannunga

---

## 🏗️ STEP 2: .EXE File ah Create Pannுங்க

1. Indha folder-ல `build_exe.bat` file ah **double-click** pannunga.
2. Adhu automatic-ah PyInstaller install pannி, .exe file ah build pannும் (2-5 நிமிடம் ஆகலாம்).
3. Build முடிஞ்சதும், `dist` nu oru புது folder வரும். Adhukulla:
   ```
   dist\TextileBilling.exe
   ```
   Indha file தான் unga final Windows software!

   > 📝 Note: Camera/QR libraries (OpenCV) சேர்ந்திருக்கிறதால இப்போ `.exe` file size கொஞ்சம் பெரிசா (100-200 MB) இருக்கும் — இது normal, problem இல்லை.

4. Indha `TextileBilling.exe` file ah shop counter PC ku copy pannitu, double-click பண்ணா software open aagum. Internet வேண்டாம், Python install பண்ண வேண்டாம் — நேரடியா ரன் ஆகும்.

> ⚠️ Important: `TextileBilling.exe` file ah எந்த folder-ல வெச்சு run பண்றீங்களோ, அதே folder-ல `textile_billing.db` (data) மற்றும் `bills` (receipt copies) automatic-ah create ஆகும். இந்த exe file ஐ ஒரு fixed folder-ல (e.g., Desktop-ல "Shop Billing" folder) வெச்சு, அங்கயே இருந்து மட்டும் run பண்ணுங்க — அப்போதான் data எல்லாம் ஒரே இடத்துல இருக்கும்.

---

## ☁️ ONLINE BUILD OPTION (GitHub Actions — PC-ல எதுவும் install பண்ணாமலே .exe கிடைக்கும்)

Unga School ERP / CSC ASK MIS APK build பண்ண use பண்ணின அதே **GitHub Actions** pattern இதுலயும் ready-ஆ வெச்சிருக்கேன் (`.github/workflows/build-exe.yml`). Idhu use பண்ண Windows PC, Python எதுவும் தேவையே இல்ல — **mobile-லேயே GitHub app/browser வச்சு** முடிக்கலாம்:

1. இந்த folder முழுவதையும் (fonts, .github ஃபோல்டர் உட்பட) unga GitHub repo-க்கு upload பண்ணுங்க (புது repo create பண்ணி, "Add file → Upload files" மூலமா)
2. GitHub-ல repo-க்குள் **"Actions"** tab-க்கு போங்க
3. **"Build Windows EXE"** workflow-ஐ தேர்வு பண்ணி **"Run workflow"** button click பண்ணுங்க
4. 3-5 நிமிடத்துல build முடியும் (green ✅ tick வரும்)
5. அந்த run-ஐ click பண்ணி, கீழே **"Artifacts"** section-ல **"TextileBilling-exe"** nu ஒரு zip கிடைக்கும் — அதை download பண்ணுங்க
6. Extract பண்ணா `TextileBilling.exe` — இதுவே unga final Windows software!

> 💡 இந்த workflow, `app.py`/`db.py`/`qr_utils.py` file-ல ஏதாவது மாற்றம் பண்ணி commit பண்ணும்போதும் **automatic-ஆ** run ஆகும் — ஒவ்வொரு தடவையும் manual-ஆ trigger பண்ண வேண்டாம்.

---

## 🖥️ Software Use Panradhu Eppadi (Simple Guide)

### 1️⃣ முதல் தடவை — Products சேர்க்கவும்
- Home screen la **"📦 Products"** button click pannunga
- Top form la பொருள் details நிரப்புங்க: பெயர், Design No, நிறம், Unit (Meter/Piece), Price, Stock Qty
- **"💾 Save"** click pannunga → கீழே table-ல list ஆகும்

### 2️⃣ Bill போடுவது
- Home screen la **"🧾 New Bill"** click pannunga
- வாடிக்கையாளர் பெயர் type பண்ணுங்க (இல்லைனா "Walk-in Customer" ஆக இருக்கும்)
- Dropdown-ல பொருள் select பண்ணி, Qty போட்டு **"➕ Add"** click பண்ணுங்க
- ஒவ்வொரு பொருளையும் இப்படி add பண்ணி cart-ல சேருங்க
- தேவைனா Discount amount போடுங்க, Payment Mode select பண்ணுங்க
- **"✅ Save & Print Bill"** click பண்ணா — bill number generate ஆகி, receipt `bills` folder-ல text file ஆக save ஆகும் (அதை open பண்ணி print பண்ணலாம்)

### 3️⃣ Reports பார்க்க
- Home screen la **"📊 Reports"** click பண்ணா, இதுவரை போட்ட எல்லா bills-ம் list ஆகி, மொத்த sales total கீழே காட்டும்

### 4️⃣ Customers Track பண்ண
- **"👥 Customers"** screen-ல புது customer add பண்ணலாம், அவங்க credit (உதவி) balance track பண்ணலாம்

---

## 🔲 QR Code Scan Feature — Eppadi Use Panradhu

### படி 1: புதிய பொருள் சேர்க்கும்போது QR code auto-create ஆகும்
- **"📦 Products"** screen-ல product details நிரப்பி Save பண்ணுங்க
- "QR/Barcode Code" field-ஐ காலியாகவே விடுங்க — Product ID தானாக அதன் QR code ஆக set ஆகும்
- (உங்க stock-ல already ஒரு barcode/code இருந்தா, அதையே இந்த field-ல type பண்ணி Save பண்ணலாம்)

### படி 2: QR code image-ஐ Generate பண்ணி Print பண்ணுங்க
- Table-ல ஒரு product-ஐ select பண்ணி **"🔳 QR உருவாக்கு / Generate QR"** click பண்ணுங்க
  → அந்த product-க்கு மட்டும் ஒரு QR image `qr_codes` folder-ல save ஆகும்
- **"🖨 எல்லாம் QR / Generate All QR"** click பண்ணா, எல்லா products-க்கும் ஒரே நேரத்தில் QR images create ஆகும்
- இந்த PNG files-ஐ open பண்ணி, print பண்ணி, பொருள் மேல் / rack மேல் label-ஆ ஒட்டுங்க

### படி 3: Billing-ல Scan பண்ணி Bill போடுங்க
"🧾 New Bill" screen-ல் **இரண்டு** வழிகள் இருக்கு:

1. **📷 Camera Scan** — "📷 கேமரா ஸ்கேன்" button click பண்ணுங்க, unga laptop/PC webcam open ஆகும். பொருளின் QR code-ஐ camera முன் காட்டுங்க — automatic-ஆ அந்த பொருள் cart-ல சேர்ந்துவிடும். தொடர்ந்து வேற பொருட்களையும் இப்படியே scan பண்ணலாம்.
2. **🔲 USB Barcode/QR Scanner** — ஒரு USB scanner வாங்கி இருந்தா (சாதாரணமா keyboard மாதிரியே வேலை செய்யும் device), scan box-ல click பண்ணி scan பண்ணுங்க — code automatic-ஆ type ஆகி Enter press ஆகி, பொருள் cart-ல சேரும்.

> 💡 Camera இல்லாத PC-ல, USB scanner box-ல அதே code-ஐ manual-ஆ type பண்ணி Enter அழுத்தினாலும் வேலை செய்யும்.

---

## 🪪 Customer ID Proof Verification (Credit/Khata Customers)

Credit (உதவி) கொடுக்கும் customer-க்கு Aadhaar/Voter ID proof verify பண்ணி வைக்கலாம்:

1. **"👥 Customers"** screen-ல் table-ல் ஒரு customer-ஐ select பண்ணுங்க
2. கீழே **"📄 ID Proof Scan & Verify பண்ணு"** click பண்ணுங்க
3. ஒரு புது window open ஆகும் — 3 படிகள்:
   - **படி 1: முன் பக்கம் (Front Page)** — 📷 Camera Capture பண்ணலாம் அல்லது 📁 Computer-ல் இருக்கும் photo file-ஐ தேர்வு பண்ணலாம்
   - **படி 2: பின் பக்கம் (Back Page)** — அதே மாதிரி Camera அல்லது File
   - **படி 3: சரிபார்ப்பு (Verification)** — இரண்டு பக்கங்களும் preview பார்த்து, **"✅ உறுதி & சேமி / Confirm & Save"** click பண்ணுங்க
4. Save ஆனதும் customer table-ல் "✅ Verified" ஆக காட்டும், மற்றும் images `customer_documents/<customer_id>/` folder-ல் save ஆகும்

> 💡 Camera இல்லாத PC-ல, unga phone-ல Aadhaar/Voter ID photo எடுத்து, USB/WhatsApp/Bluetooth வழி PC-க்கு கொண்டுவந்து, "📁 Choose File" option வைத்து அதே photo-வை select பண்ணலாம்.

### 👁 Verified Details பார்க்க
- "👥 Customers" screen-ல் ஒரு customer select பண்ணி **"👁 விவரம் பார் / View Details"** click பண்ணுங்க
- ஒரு window open ஆகி, phone/address/credit balance/verification status/verified date காட்டும், verify ஆகி இருந்தா front & back ID images-ம் காட்டும்

---

## 🎨 Button Design
எல்லா buttons-ம் இப்போ **oval/pill shape**-ல் இருக்கும் (rounded ends), ஒரு modern, easy-to-tap look கொடுக்க.

## 🔧 Future Additions (Neenga Kekkalam)

இந்த version stable-ah, simple-ah இருக்கும் padi design pannirukken. Adutha step-ல இதை மேலும் develop பண்ணலாம்:
- Thermal printer-ku direct print (ESC/POS)
- Barcode scanner support
- Excel export for reports
- Multi-PC / LAN sync
- Cloud backup (InfinityFree/Aiven போல unga existing pattern use பண்ணி)

இதுல ஏதாவது add பண்ணனும்னா சொல்லுங்க, step-by-step பண்ணித் தருகிறேன்.
