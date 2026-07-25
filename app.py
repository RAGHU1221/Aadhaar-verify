"""
Textile Shop Billing Software
=============================
Bilingual (Tamil + English) desktop billing app for a textile/cloth shop.
Built with Tkinter (comes free with Python - no extra install needed) and
SQLite (also built-in). This keeps the app light and easy to turn into a
single Windows .exe file with PyInstaller.

Run with:  python app.py
"""

import tkinter as tk
from tkinter import ttk, messagebox, filedialog
import platform
import os
import sys
import shutil

import db
import qr_utils

try:
    from PIL import Image, ImageTk
    PIL_AVAILABLE = True
except ImportError:
    PIL_AVAILABLE = False

# ---------- COLOURS & FONTS (kept in one place so the whole app is easy to re-skin) ----------
COLOR_PRIMARY = "#6a1b9a"      # purple
COLOR_PRIMARY_DARK = "#4a148c"
COLOR_ACCENT = "#ff7043"       # orange
COLOR_SUCCESS = "#2e7d32"      # green
COLOR_BG = "#faf5fc"
COLOR_CARD = "#ffffff"
COLOR_TEXT = "#2d2d2d"
COLOR_DANGER = "#c62828"

def resource_path(relative_path):
    """
    Finds a bundled file whether we're running as a plain .py script
    or as a PyInstaller-built .exe (where files are unpacked to a
    temporary _MEIPASS folder at runtime).
    """
    try:
        base_path = sys._MEIPASS  # type: ignore[attr-defined]
    except AttributeError:
        base_path = os.path.abspath(os.path.dirname(__file__))
    return os.path.join(base_path, relative_path)


def load_bundled_tamil_font():
    """
    Loads our own copy of 'Noto Sans Tamil' (shipped in the fonts/ folder)
    as a private, per-process font - so Tamil text renders correctly
    even on a shop PC that doesn't have a Tamil font installed.
    Falls back to a sensible default if this fails for any reason.
    """
    font_regular = resource_path(os.path.join("fonts", "NotoSansTamil-Regular.ttf"))
    font_bold = resource_path(os.path.join("fonts", "NotoSansTamil-Bold.ttf"))

    if platform.system() == "Windows":
        try:
            import ctypes
            FR_PRIVATE = 0x10
            loaded_any = False
            for path in (font_regular, font_bold):
                if os.path.exists(path):
                    result = ctypes.windll.gdi32.AddFontResourceExW(path, FR_PRIVATE, 0)
                    if result > 0:
                        loaded_any = True
            if loaded_any:
                return "Noto Sans Tamil"
        except Exception:
            pass
        return "Nirmala UI"  # ships with Windows 8+ and supports Tamil
    else:
        # Linux/Mac dev & testing environment - relies on a system Tamil font
        return "Noto Sans Tamil"


TAMIL_FONT_FAMILY = load_bundled_tamil_font()

FONT_TITLE = (TAMIL_FONT_FAMILY, 20, "bold")
FONT_SUBTITLE = (TAMIL_FONT_FAMILY, 12)
FONT_LABEL = (TAMIL_FONT_FAMILY, 11)
FONT_BUTTON = (TAMIL_FONT_FAMILY, 12, "bold")
FONT_BIG_TOTAL = (TAMIL_FONT_FAMILY, 22, "bold")
FONT_TABLE = (TAMIL_FONT_FAMILY, 10)


class RoundedButton(tk.Canvas):
    """
    A pill/oval-shaped clickable button drawn on a Canvas, since plain
    tk.Button cannot have rounded corners on every platform. Supports
    multi-line text, a background matching its parent, and a hover effect.
    """
    def __init__(self, parent, text, command=None, bg=COLOR_PRIMARY, fg="white",
                 width_px=160, height_px=46, font=None, radius=None):
        parent_bg = COLOR_BG
        try:
            parent_bg = parent.cget("bg")
        except Exception:
            pass
        super().__init__(parent, width=width_px, height=height_px, bg=parent_bg, highlightthickness=0)
        self.command = command
        self.bg_color = bg
        self.fg_color = fg
        self.hover_color = self._shade(bg, 0.85)
        self.press_color = self._shade(bg, 0.7)
        self.font = font or FONT_BUTTON
        self.text = text
        self.width_px = width_px
        self.height_px = height_px
        self.radius = radius if radius is not None else height_px / 2

        self._draw(self.bg_color)
        self.bind("<Enter>", lambda e: self._draw(self.hover_color))
        self.bind("<Leave>", lambda e: self._draw(self.bg_color))
        self.bind("<ButtonPress-1>", lambda e: self._draw(self.press_color))
        self.bind("<ButtonRelease-1>", self._on_release)
        self.configure(cursor="hand2")

    def _draw(self, color):
        self.delete("all")
        w, h, r = self.width_px, self.height_px, self.radius
        r = min(r, h / 2, w / 2)
        # Build a pill/oval shape out of two circles + a rectangle in between
        self.create_oval(0, 0, r * 2, h, fill=color, outline=color)
        self.create_oval(w - r * 2, 0, w, h, fill=color, outline=color)
        if w - 2 * r > 0:
            self.create_rectangle(r, 0, w - r, h, fill=color, outline=color)
        self.create_text(w / 2, h / 2, text=self.text, fill=self.fg_color,
                          font=self.font, justify="center", width=w - 12)

    def _on_release(self, event):
        self._draw(self.hover_color)
        if self.command:
            self.command()

    @staticmethod
    def _shade(hex_color, factor):
        hex_color = hex_color.lstrip("#")
        if len(hex_color) != 6:
            return hex_color
        r, g, b = (int(hex_color[i:i + 2], 16) for i in (0, 2, 4))
        r, g, b = int(r * factor), int(g * factor), int(b * factor)
        return f"#{r:02x}{g:02x}{b:02x}"


def make_button(parent, text, command, bg=COLOR_PRIMARY, fg="white", width=22, height=2, font=FONT_BUTTON):
    """
    Kept the same signature as before (width = character units, height = line units)
    so every existing call site works unchanged, but now renders an oval/pill button.
    """
    width_px = max(110, int(width * 9) + 40)
    height_px = max(38, int(height * 26) + 20)
    return RoundedButton(parent, text, command, bg=bg, fg=fg, width_px=width_px, height_px=height_px, font=font)


class TextileBillingApp(tk.Tk):
    def __init__(self):
        super().__init__()
        self.title("டெக்ஸ்டைல் பில்லிங் மென்பொருள் / Textile Billing Software")
        self.geometry("1000x650")
        self.configure(bg=COLOR_BG)
        self.minsize(900, 600)

        db.init_db()

        # Make sure ttk widgets (Treeview tables, Comboboxes) also use our
        # bundled Tamil font - by default they use a system font that may
        # not have Tamil glyphs, even after we fix the plain tk widgets.
        style = ttk.Style(self)
        style.configure("Treeview", font=FONT_TABLE, rowheight=26)
        style.configure("Treeview.Heading", font=(TAMIL_FONT_FAMILY, 10, "bold"))

        # Container that holds every "page" (screen) of the app
        self.container = tk.Frame(self, bg=COLOR_BG)
        self.container.pack(fill="both", expand=True)

        self.frames = {}
        for PageClass in (HomePage, BillingPage, ProductsPage, CustomersPage, ReportsPage):
            frame = PageClass(self.container, self)
            self.frames[PageClass.__name__] = frame
            frame.place(relwidth=1, relheight=1)

        self.show_frame("HomePage")

    def show_frame(self, name):
        frame = self.frames[name]
        if hasattr(frame, "on_show"):
            frame.on_show()
        frame.tkraise()


# ---------------------------------------------------------------------------
# HOME PAGE
# ---------------------------------------------------------------------------
class HomePage(tk.Frame):
    def __init__(self, parent, controller):
        super().__init__(parent, bg=COLOR_BG)
        self.controller = controller

        header = tk.Frame(self, bg=COLOR_PRIMARY, height=110)
        header.pack(fill="x")
        tk.Label(header, text="🧵 டெக்ஸ்டைல் ஷாப் பில்லிங்", font=FONT_TITLE,
                  bg=COLOR_PRIMARY, fg="white").pack(pady=(18, 0))
        tk.Label(header, text="Textile Shop Billing Software", font=FONT_SUBTITLE,
                  bg=COLOR_PRIMARY, fg="#f0e6f6").pack(pady=(0, 15))

        body = tk.Frame(self, bg=COLOR_BG)
        body.pack(expand=True)

        tk.Label(body, text="என்ன செய்ய வேண்டும்? / What do you want to do?",
                 font=FONT_SUBTITLE, bg=COLOR_BG, fg=COLOR_TEXT).pack(pady=(30, 20))

        grid = tk.Frame(body, bg=COLOR_BG)
        grid.pack()

        buttons = [
            ("🧾 புதிய பில் \nNew Bill", COLOR_PRIMARY, lambda: controller.show_frame("BillingPage")),
            ("📦 பொருட்கள் \nProducts", COLOR_ACCENT, lambda: controller.show_frame("ProductsPage")),
            ("👥 வாடிக்கையாளர்கள் \nCustomers", COLOR_SUCCESS, lambda: controller.show_frame("CustomersPage")),
            ("📊 அறிக்கை \nReports", "#0078d4", lambda: controller.show_frame("ReportsPage")),
        ]
        for i, (text, color, cmd) in enumerate(buttons):
            b = make_button(grid, text, cmd, bg=color, width=20, height=4, font=(TAMIL_FONT_FAMILY, 13, "bold"))
            b.grid(row=i // 2, column=i % 2, padx=18, pady=14)

        make_button(body, "வெளியேறு / Exit", controller.destroy,
                    bg="#eeeeee", fg="#555", width=14, height=1, font=FONT_LABEL).pack(pady=(30, 10))


# ---------------------------------------------------------------------------
# BILLING PAGE (the main screen - create a new bill)
# ---------------------------------------------------------------------------
class BillingPage(tk.Frame):
    def __init__(self, parent, controller):
        super().__init__(parent, bg=COLOR_BG)
        self.controller = controller
        self.cart = []  # list of dicts: product_id, name, qty, unit, rate, subtotal
        self.selected_customer_id = None

        self.build_header()
        self.build_customer_row()
        self.build_scan_row()
        self.build_product_row()
        self.build_cart_table()
        self.build_totals_row()

    def on_show(self):
        self.refresh_product_list()

    def build_header(self):
        header = tk.Frame(self, bg=COLOR_PRIMARY, height=60)
        header.pack(fill="x")
        make_button(header, "⬅ முகப்பு / Home", lambda: self.controller.show_frame("HomePage"),
                    bg=COLOR_PRIMARY_DARK, width=14, height=1, font=FONT_LABEL).pack(side="left", padx=12, pady=12)
        tk.Label(header, text="🧾 புதிய பில் / New Bill", font=(TAMIL_FONT_FAMILY, 16, "bold"),
                  bg=COLOR_PRIMARY, fg="white").pack(side="left", padx=20)

    def build_customer_row(self):
        row = tk.Frame(self, bg=COLOR_BG)
        row.pack(fill="x", padx=20, pady=(14, 6))

        tk.Label(row, text="வாடிக்கையாளர் பெயர் / Customer Name:", font=FONT_LABEL, bg=COLOR_BG).grid(row=0, column=0, sticky="w")
        self.customer_var = tk.StringVar()
        self.customer_entry = tk.Entry(row, textvariable=self.customer_var, font=FONT_LABEL, width=25)
        self.customer_entry.grid(row=0, column=1, padx=8)
        tk.Label(row, text="(காலியாக விட்டால் Walk-in Customer)", font=(TAMIL_FONT_FAMILY, 9), fg="#888", bg=COLOR_BG).grid(row=0, column=2, padx=6)

    def build_scan_row(self):
        row = tk.Frame(self, bg="#fff3e0", relief="ridge", bd=1)
        row.pack(fill="x", padx=20, pady=(4, 6))

        tk.Label(row, text="🔲 QR/Barcode Scan பண்ணுங்க (அல்லது code type பண்ணி Enter அழுத்துங்க):",
                 font=FONT_LABEL, bg="#fff3e0", fg="#d84315").pack(side="left", padx=10, pady=8)

        self.scan_var = tk.StringVar()
        self.scan_entry = tk.Entry(row, textvariable=self.scan_var, font=FONT_LABEL, width=20)
        self.scan_entry.pack(side="left", padx=6)
        self.scan_entry.bind("<Return>", self.on_scan_entry_submit)

        make_button(row, "📷 கேமரா ஸ்கேன் / Camera Scan", self.open_camera_scanner, bg="#d84315",
                    width=24, height=1, font=(TAMIL_FONT_FAMILY, 10)).pack(side="left", padx=10)

    def build_product_row(self):
        row = tk.Frame(self, bg=COLOR_BG)
        row.pack(fill="x", padx=20, pady=6)

        tk.Label(row, text="பொருள் தேர்வு / Select Product:", font=FONT_LABEL, bg=COLOR_BG).grid(row=0, column=0, sticky="w")
        self.product_combo = ttk.Combobox(row, font=FONT_LABEL, width=35, state="readonly")
        self.product_combo.grid(row=0, column=1, padx=8)

        tk.Label(row, text="அளவு / Qty:", font=FONT_LABEL, bg=COLOR_BG).grid(row=0, column=2, padx=(14, 4))
        self.qty_var = tk.StringVar(value="1")
        tk.Entry(row, textvariable=self.qty_var, font=FONT_LABEL, width=6).grid(row=0, column=3)

        make_button(row, "➕ சேர் / Add", self.add_to_cart, bg=COLOR_SUCCESS, width=14, height=1,
                    font=FONT_LABEL).grid(row=0, column=4, padx=14)

        self.products_cache = []  # list of full product rows matching combo index

    def build_cart_table(self):
        frame = tk.Frame(self, bg=COLOR_BG)
        frame.pack(fill="both", expand=True, padx=20, pady=10)

        columns = ("name", "qty", "unit", "rate", "subtotal")
        self.cart_tree = ttk.Treeview(frame, columns=columns, show="headings", height=10)
        headers = {
            "name": "பொருள் / Item",
            "qty": "அளவு / Qty",
            "unit": "அலகு / Unit",
            "rate": "விலை / Rate",
            "subtotal": "தொகை / Subtotal",
        }
        for col in columns:
            self.cart_tree.heading(col, text=headers[col])
            self.cart_tree.column(col, width=150 if col == "name" else 100, anchor="center")
        self.cart_tree.pack(side="left", fill="both", expand=True)

        scrollbar = ttk.Scrollbar(frame, orient="vertical", command=self.cart_tree.yview)
        scrollbar.pack(side="right", fill="y")
        self.cart_tree.configure(yscrollcommand=scrollbar.set)

        make_button(self, "🗑 நீக்கு / Remove Selected Item", self.remove_selected, bg=COLOR_DANGER,
                    width=28, height=1, font=(TAMIL_FONT_FAMILY, 10)).pack(pady=(0, 6))

    def build_totals_row(self):
        row = tk.Frame(self, bg=COLOR_BG)
        row.pack(fill="x", padx=20, pady=10)

        tk.Label(row, text="தள்ளுபடி / Discount (₹):", font=FONT_LABEL, bg=COLOR_BG).grid(row=0, column=0, sticky="w")
        self.discount_var = tk.StringVar(value="0")
        self.discount_var.trace_add("write", lambda *a: self.update_total())
        tk.Entry(row, textvariable=self.discount_var, font=FONT_LABEL, width=8).grid(row=0, column=1, padx=8)

        tk.Label(row, text="பணம் முறை / Payment Mode:", font=FONT_LABEL, bg=COLOR_BG).grid(row=0, column=2, padx=(20, 4))
        self.payment_combo = ttk.Combobox(row, font=FONT_LABEL, width=20, state="readonly",
                                           values=["Cash / பணம்", "UPI", "Card / கார்டு", "Credit / உதவி"])
        self.payment_combo.current(0)
        self.payment_combo.grid(row=0, column=3)

        self.total_label = tk.Label(row, text="மொத்தம் / Total: ₹0.00", font=FONT_BIG_TOTAL,
                                     bg=COLOR_BG, fg=COLOR_PRIMARY)
        self.total_label.grid(row=1, column=0, columnspan=4, pady=(14, 4), sticky="w")

        make_button(row, "✅ பில் சேமி & பிரிண்ட் / Save & Print Bill", self.save_bill,
                    bg=COLOR_ACCENT, width=32, height=2).grid(row=2, column=0, columnspan=4, pady=10)

    # ---------------- logic ----------------

    def refresh_product_list(self):
        self.products_cache = db.get_products()
        display_values = [
            f"{p[1]} | {p[2] or '-'} | {p[3] or '-'} | ₹{p[5]:.2f} | Stock:{p[6]:.1f}"
            for p in self.products_cache
        ]
        self.product_combo["values"] = display_values
        if display_values:
            self.product_combo.current(0)

    def add_to_cart(self):
        idx = self.product_combo.current()
        if idx < 0 or not self.products_cache:
            messagebox.showwarning("பொருள் இல்லை / No product", "முதலில் ஒரு பொருளை தேர்வு செய்யவும்.\nPlease select a product first.")
            return
        try:
            qty = float(self.qty_var.get())
            if qty <= 0:
                raise ValueError
        except ValueError:
            messagebox.showerror("தவறான அளவு / Invalid Qty", "சரியான அளவு (எண்) கொடுக்கவும்.\nPlease enter a valid quantity.")
            return

        product = self.products_cache[idx]
        product_id, name, design_no, color, unit, price, stock, qr_code = product
        self._add_product_to_cart(product_id, name, unit, price, stock, qty)

    def on_scan_entry_submit(self, event=None):
        """Called when a USB barcode/QR scanner (or manual typing) sends Enter."""
        code = self.scan_var.get().strip()
        self.scan_var.set("")
        if not code:
            return
        self.add_by_code(code)

    def add_by_code(self, code, qty=1):
        """Looks up a product by its scanned QR/barcode code and adds it to the cart."""
        product = db.get_product_by_code(code)
        if not product:
            messagebox.showwarning(
                "பொருள் கிடைக்கவில்லை / Product not found",
                f"இந்த code-க்கு பொருள் இல்லை: {code}\nNo product found for this code."
            )
            return False
        product_id, name, design_no, color, unit, price, stock, qr_code = product
        self._add_product_to_cart(product_id, name, unit, price, stock, qty)
        return True

    def _add_product_to_cart(self, product_id, name, unit, price, stock, qty):
        if qty > stock:
            messagebox.showwarning(
                "போதிய ஸ்டாக் இல்லை / Not enough stock",
                f"கிடைக்கும் ஸ்டாக்: {stock}\nAvailable stock: {stock}"
            )
            return

        subtotal = round(qty * price, 2)
        self.cart.append({
            "product_id": product_id, "name": name, "qty": qty,
            "unit": unit, "rate": price, "subtotal": subtotal,
        })
        self.cart_tree.insert("", "end", values=(name, qty, unit, f"{price:.2f}", f"{subtotal:.2f}"))
        self.update_total()

    def open_camera_scanner(self):
        CameraScanWindow(self, on_code_scanned=self.add_by_code)

    def remove_selected(self):
        selected = self.cart_tree.selection()
        if not selected:
            return
        for item_id in selected:
            index = self.cart_tree.index(item_id)
            self.cart_tree.delete(item_id)
            del self.cart[index]
        self.update_total()

    def update_total(self):
        subtotal_sum = sum(item["subtotal"] for item in self.cart)
        try:
            discount = float(self.discount_var.get() or 0)
        except ValueError:
            discount = 0
        grand_total = max(subtotal_sum - discount, 0)
        self.total_label.config(text=f"மொத்தம் / Total: ₹{grand_total:.2f}")

    def save_bill(self):
        if not self.cart:
            messagebox.showwarning("பில் காலியாக உள்ளது / Empty bill", "தயவுசெய்து பொருட்களை சேர்க்கவும்.\nPlease add at least one item.")
            return

        customer_name = self.customer_var.get().strip() or "Walk-in Customer"
        try:
            discount = float(self.discount_var.get() or 0)
        except ValueError:
            discount = 0
        payment_mode = self.payment_combo.get()

        bill_id, bill_no, grand_total = db.create_bill(
            customer_id=None, customer_name=customer_name,
            cart_items=self.cart, discount=discount, payment_mode=payment_mode,
        )

        items_for_receipt = [(i["name"], i["qty"], i["unit"], i["rate"], i["subtotal"]) for i in self.cart]
        path = db.save_receipt_text(
            bill_id, bill_no, customer_name, items_for_receipt, discount, grand_total,
            payment_mode, __import__("datetime").datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        )

        messagebox.showinfo(
            "பில் தயார் / Bill Saved",
            f"பில் எண்: {bill_no}\nமொத்தம்: ₹{grand_total:.2f}\n\nரசீது சேமிக்கப்பட்டது:\n{path}\n\n"
            f"Bill No: {bill_no}\nTotal: ₹{grand_total:.2f}\nReceipt saved to: {path}"
        )

        # reset the screen for the next bill
        self.cart.clear()
        for row in self.cart_tree.get_children():
            self.cart_tree.delete(row)
        self.customer_var.set("")
        self.discount_var.set("0")
        self.update_total()
        self.refresh_product_list()


# ---------------------------------------------------------------------------
# CAMERA QR SCAN WINDOW (used from the Billing page)
# ---------------------------------------------------------------------------
class CameraScanWindow(tk.Toplevel):
    """
    A small popup window that shows a live webcam feed and automatically
    adds the product to the cart as soon as a known QR code is detected.
    Keeps scanning so multiple items can be added one after another.
    """
    def __init__(self, parent, on_code_scanned):
        super().__init__(parent)
        self.title("📷 QR ஸ்கேன் / Camera QR Scan")
        self.geometry("520x480")
        self.configure(bg=COLOR_BG)
        self.on_code_scanned = on_code_scanned
        self.last_code = None
        self.last_code_time = 0
        self._closed = False

        tk.Label(self, text="கேமராவை பொருளின் QR code முன் வையுங்கள்",
                 font=FONT_LABEL, bg=COLOR_BG, fg=COLOR_PRIMARY).pack(pady=(10, 2))
        tk.Label(self, text="Point the camera at the product's QR code",
                 font=(TAMIL_FONT_FAMILY, 9), bg=COLOR_BG, fg="#888").pack()

        self.video_label = tk.Label(self, bg="black")
        self.video_label.pack(padx=10, pady=10)

        self.status_label = tk.Label(self, text="", font=FONT_LABEL, bg=COLOR_BG, fg=COLOR_SUCCESS)
        self.status_label.pack(pady=4)

        make_button(self, "❌ மூடு / Close", self.close_window, bg=COLOR_DANGER, width=16, height=1).pack(pady=8)

        self.protocol("WM_DELETE_WINDOW", self.close_window)

        if not qr_utils.CAMERA_SUPPORT:
            self.status_label.config(
                text="⚠ Camera library இல்லை. requirements.txt install பண்ணுங்க.\n(opencv-python, pyzbar not installed)",
                fg=COLOR_DANGER,
            )
            return

        self.scanner = qr_utils.CameraQRScanner()
        if not self.scanner.available:
            self.status_label.config(
                text="⚠ Camera கிடைக்கவில்லை. USB scanner-ஆ code type பண்ணி Enter அழுத்தவும்.\nCamera not found - use the manual scan box instead.",
                fg=COLOR_DANGER,
            )
            return

        self.update_frame()

    def update_frame(self):
        if self._closed:
            return
        frame, code = self.scanner.read_frame()
        if frame is not None and PIL_AVAILABLE:
            import cv2
            rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            img = Image.fromarray(rgb).resize((480, 360))
            imgtk = ImageTk.PhotoImage(image=img)
            self.video_label.imgtk = imgtk  # keep a reference so it isn't garbage-collected
            self.video_label.configure(image=imgtk)

        if code:
            import time
            now = time.time()
            # avoid re-adding the same code repeatedly while it's still in view
            if code != self.last_code or (now - self.last_code_time) > 2.0:
                self.last_code = code
                self.last_code_time = now
                added = self.on_code_scanned(code, 1)
                if added:
                    self.status_label.config(text=f"✅ சேர்க்கப்பட்டது / Added: {code}", fg=COLOR_SUCCESS)
                else:
                    self.status_label.config(text=f"❌ கிடைக்கவில்லை / Not found: {code}", fg=COLOR_DANGER)

        if not self._closed:
            self.after(80, self.update_frame)

    def close_window(self):
        self._closed = True
        if hasattr(self, "scanner"):
            self.scanner.release()
        self.destroy()


# ---------------------------------------------------------------------------
# PRODUCTS PAGE
# ---------------------------------------------------------------------------
class ProductsPage(tk.Frame):
    def __init__(self, parent, controller):
        super().__init__(parent, bg=COLOR_BG)
        self.controller = controller
        self.editing_id = None

        header = tk.Frame(self, bg=COLOR_ACCENT, height=60)
        header.pack(fill="x")
        make_button(header, "⬅ முகப்பு / Home", lambda: controller.show_frame("HomePage"),
                    bg="#e05a2b", width=14, height=1, font=FONT_LABEL).pack(side="left", padx=12, pady=12)
        tk.Label(header, text="📦 பொருட்கள் / Products", font=(TAMIL_FONT_FAMILY, 16, "bold"),
                  bg=COLOR_ACCENT, fg="white").pack(side="left", padx=20)

        form = tk.LabelFrame(self, text="புதிய பொருள் / Add or Edit Product", font=FONT_LABEL, bg=COLOR_BG, fg=COLOR_PRIMARY)
        form.pack(fill="x", padx=20, pady=12)

        labels = ["பெயர் / Name", "டிசைன் நம்பர் / Design No", "நிறம் / Color", "அலகு / Unit (Meter/Piece)",
                  "விலை / Price (₹)", "ஸ்டாக் / Stock Qty", "QR/Barcode Code (விருப்பம்/optional)"]
        self.entries = {}
        for i, label in enumerate(labels):
            tk.Label(form, text=label, font=FONT_LABEL, bg=COLOR_BG).grid(row=i // 3, column=(i % 3) * 2, sticky="w", padx=8, pady=6)
            e = tk.Entry(form, font=FONT_LABEL, width=18)
            e.grid(row=i // 3, column=(i % 3) * 2 + 1, padx=8, pady=6)
            self.entries[label] = e

        tk.Label(form, text="(காலியா விட்டா, Product ID தானாக QR code ஆக இருக்கும்)",
                 font=(TAMIL_FONT_FAMILY, 8), fg="#888", bg=COLOR_BG).grid(row=2, column=4, columnspan=2, sticky="w")

        btn_row = tk.Frame(form, bg=COLOR_BG)
        btn_row.grid(row=3, column=0, columnspan=6, pady=8)
        make_button(btn_row, "💾 சேமி / Save", self.save_product, bg=COLOR_SUCCESS, width=14, height=1).pack(side="left", padx=6)
        make_button(btn_row, "🧹 அழி / Clear", self.clear_form, bg="#888", width=12, height=1).pack(side="left", padx=6)
        make_button(btn_row, "🔳 QR உருவாக்கு / Generate QR", self.generate_qr_selected,
                    bg=COLOR_PRIMARY, width=22, height=1, font=(TAMIL_FONT_FAMILY, 10)).pack(side="left", padx=6)
        make_button(btn_row, "🖨 எல்லாம் QR / Generate All QR", self.generate_qr_all,
                    bg="#0078d4", width=22, height=1, font=(TAMIL_FONT_FAMILY, 10)).pack(side="left", padx=6)

        search_row = tk.Frame(self, bg=COLOR_BG)
        search_row.pack(fill="x", padx=20)
        tk.Label(search_row, text="தேடு / Search:", font=FONT_LABEL, bg=COLOR_BG).pack(side="left")
        self.search_var = tk.StringVar()
        self.search_var.trace_add("write", lambda *a: self.refresh_table())
        tk.Entry(search_row, textvariable=self.search_var, font=FONT_LABEL, width=30).pack(side="left", padx=8)

        table_frame = tk.Frame(self, bg=COLOR_BG)
        table_frame.pack(fill="both", expand=True, padx=20, pady=10)
        columns = ("id", "name", "design", "color", "unit", "price", "stock", "qr_code")
        self.tree = ttk.Treeview(table_frame, columns=columns, show="headings", height=10)
        headers = {"id": "ID", "name": "பெயர்/Name", "design": "Design No", "color": "நிறம்/Color",
                   "unit": "அலகு/Unit", "price": "விலை/Price", "stock": "ஸ்டாக்/Stock", "qr_code": "QR Code"}
        for col in columns:
            self.tree.heading(col, text=headers[col])
            self.tree.column(col, width=70 if col == "id" else 110, anchor="center")
        self.tree.pack(side="left", fill="both", expand=True)
        self.tree.bind("<<TreeviewSelect>>", self.load_selected)

        scrollbar = ttk.Scrollbar(table_frame, orient="vertical", command=self.tree.yview)
        scrollbar.pack(side="right", fill="y")
        self.tree.configure(yscrollcommand=scrollbar.set)

        make_button(self, "🗑 தேர்ந்தெடுத்ததை நீக்கு / Delete Selected", self.delete_product,
                    bg=COLOR_DANGER, width=30, height=1, font=(TAMIL_FONT_FAMILY, 10)).pack(pady=(0, 10))

    def on_show(self):
        self.refresh_table()

    def refresh_table(self):
        for row in self.tree.get_children():
            self.tree.delete(row)
        for p in db.get_products(self.search_var.get()):
            self.tree.insert("", "end", values=p)

    def load_selected(self, event=None):
        selected = self.tree.selection()
        if not selected:
            return
        values = self.tree.item(selected[0])["values"]
        self.editing_id = values[0]
        keys = ["பெயர் / Name", "டிசைன் நம்பர் / Design No", "நிறம் / Color", "அலகு / Unit (Meter/Piece)",
                "விலை / Price (₹)", "ஸ்டாக் / Stock Qty", "QR/Barcode Code (விருப்பம்/optional)"]
        for key, val in zip(keys, values[1:]):
            self.entries[key].delete(0, tk.END)
            self.entries[key].insert(0, val)

    def clear_form(self):
        self.editing_id = None
        for e in self.entries.values():
            e.delete(0, tk.END)

    def save_product(self):
        try:
            name = self.entries["பெயர் / Name"].get().strip()
            design_no = self.entries["டிசைன் நம்பர் / Design No"].get().strip()
            color = self.entries["நிறம் / Color"].get().strip()
            unit = self.entries["அலகு / Unit (Meter/Piece)"].get().strip() or "Piece"
            price = float(self.entries["விலை / Price (₹)"].get() or 0)
            stock = float(self.entries["ஸ்டாக் / Stock Qty"].get() or 0)
            qr_code = self.entries["QR/Barcode Code (விருப்பம்/optional)"].get().strip() or None
        except ValueError:
            messagebox.showerror("தவறு / Error", "விலை மற்றும் ஸ்டாக் எண்ணாக இருக்க வேண்டும்.\nPrice and Stock must be numbers.")
            return

        if not name:
            messagebox.showerror("தவறு / Error", "பொருள் பெயர் கட்டாயம்.\nProduct name is required.")
            return

        if self.editing_id:
            db.update_product(self.editing_id, name, design_no, color, unit, price, stock, qr_code)
        else:
            db.add_product(name, design_no, color, unit, price, stock, qr_code)

        self.clear_form()
        self.refresh_table()

    def delete_product(self):
        selected = self.tree.selection()
        if not selected:
            return
        if messagebox.askyesno("உறுதிப்படுத்தவும் / Confirm", "இந்த பொருளை நீக்கவா?\nDelete this product?"):
            product_id = self.tree.item(selected[0])["values"][0]
            db.delete_product(product_id)
            self.refresh_table()

    def generate_qr_selected(self):
        selected = self.tree.selection()
        if not selected:
            messagebox.showwarning("பொருள் தேர்வு / Select a product", "முதலில் table-ல் ஒரு பொருளை தேர்வு செய்யவும்.\nSelect a product from the table first.")
            return
        values = self.tree.item(selected[0])["values"]
        product_id, name, qr_code = values[0], values[1], values[7]
        code_value = qr_code or str(product_id)
        path = qr_utils.generate_qr_image(code_value, name)
        messagebox.showinfo("QR தயார் / QR Generated", f"QR code image save ஆனது:\n{path}\n\nஇதை print பண்ணி பொருள் மேல் ஒட்டலாம்.")

    def generate_qr_all(self):
        products = db.get_products()
        if not products:
            messagebox.showwarning("பொருட்கள் இல்லை / No products", "முதலில் பொருட்களை சேர்க்கவும்.\nAdd some products first.")
            return
        folder = qr_utils.generate_qr_for_all(products)
        messagebox.showinfo("QR தயார் / QR Codes Generated", f"{len(products)} QR codes இந்த folder-ல save ஆனது:\n{folder}")


# ---------------------------------------------------------------------------
# CUSTOMER ID PROOF VERIFICATION WINDOW (Aadhaar / Voter ID - front & back)
# ---------------------------------------------------------------------------
class DocumentVerificationWindow(tk.Toplevel):
    """
    Step-by-step flow for a credit/khata customer's ID proof:
      Step 1: capture/select the FRONT page image
      Step 2: capture/select the BACK page image
      Step 3: show both, confirm verification, save
    Images are copied into: customer_documents/<customer_id>/front.jpg & back.jpg
    """
    DOCS_FOLDER = "customer_documents"

    def __init__(self, parent, customer_id, customer_name, on_saved=None):
        super().__init__(parent)
        self.customer_id = customer_id
        self.customer_name = customer_name
        self.on_saved = on_saved
        self.step = 1  # 1 = front, 2 = back, 3 = confirm
        self.front_temp_path = None
        self.back_temp_path = None
        self.camera = None
        self._closed = False

        self.title(f"📄 ID Proof Verification — {customer_name}")
        self.geometry("560x560")
        self.configure(bg=COLOR_BG)
        self.protocol("WM_DELETE_WINDOW", self.close_window)

        self.header_label = tk.Label(self, text="", font=(TAMIL_FONT_FAMILY, 13, "bold"),
                                      bg=COLOR_BG, fg=COLOR_PRIMARY)
        self.header_label.pack(pady=(14, 4))

        self.preview_label = tk.Label(self, bg="black", width=480, height=320)
        self.preview_label.pack(pady=10)

        self.status_label = tk.Label(self, text="", font=FONT_LABEL, bg=COLOR_BG, fg=COLOR_SUCCESS)
        self.status_label.pack(pady=4)

        self.btn_row1 = tk.Frame(self, bg=COLOR_BG)
        self.btn_row1.pack(pady=6)

        self.btn_row2 = tk.Frame(self, bg=COLOR_BG)
        self.btn_row2.pack(pady=6)

        self.show_step_1()

    # ---------- STEP 1: FRONT PAGE ----------
    def show_step_1(self):
        self.step = 1
        self.header_label.config(
            text=f"படி 1/3 — முன் பக்கம் (Front Page) — {self.customer_name}\nStep 1/3 — Front Page of ID"
        )
        self.status_label.config(text="")
        self._clear_buttons()
        self._show_placeholder("Front page இன்னும் இல்லை / No front page yet")

        make_button(self.btn_row1, "📷 கேமரா Capture / Camera Capture", self.capture_front_camera,
                    bg="#0078d4", width=28, height=1, font=(TAMIL_FONT_FAMILY, 10)).pack(side="left", padx=6)
        make_button(self.btn_row1, "📁 Computer-ல் இருந்து தேர்வு / Choose File", self.choose_front_file,
                    bg=COLOR_SUCCESS, width=28, height=1, font=(TAMIL_FONT_FAMILY, 10)).pack(side="left", padx=6)

    def capture_front_camera(self):
        self._open_camera_capture(step_target=1)

    def choose_front_file(self):
        path = filedialog.askopenfilename(title="Front Page Image தேர்வு செய்யவும்",
                                           filetypes=[("Image files", "*.jpg *.jpeg *.png")])
        if path:
            self.front_temp_path = path
            self._show_image_file(path)
            self._show_next_button(self.show_step_2)

    # ---------- STEP 2: BACK PAGE ----------
    def show_step_2(self):
        self.step = 2
        self.header_label.config(
            text=f"படி 2/3 — பின் பக்கம் (Back Page) — {self.customer_name}\nStep 2/3 — Back Page of ID"
        )
        self.status_label.config(text="✅ Front page தயார்! / Front page ready!", fg=COLOR_SUCCESS)
        self._clear_buttons()
        self._show_placeholder("Back page இன்னும் இல்லை / No back page yet")

        make_button(self.btn_row1, "📷 கேமரா Capture / Camera Capture", self.capture_back_camera,
                    bg="#0078d4", width=28, height=1, font=(TAMIL_FONT_FAMILY, 10)).pack(side="left", padx=6)
        make_button(self.btn_row1, "📁 Computer-ல் இருந்து தேர்வு / Choose File", self.choose_back_file,
                    bg=COLOR_SUCCESS, width=28, height=1, font=(TAMIL_FONT_FAMILY, 10)).pack(side="left", padx=6)

    def capture_back_camera(self):
        self._open_camera_capture(step_target=2)

    def choose_back_file(self):
        path = filedialog.askopenfilename(title="Back Page Image தேர்வு செய்யவும்",
                                           filetypes=[("Image files", "*.jpg *.jpeg *.png")])
        if path:
            self.back_temp_path = path
            self._show_image_file(path)
            self._show_next_button(self.show_step_3)

    # ---------- STEP 3: CONFIRM & SAVE ----------
    def show_step_3(self):
        self.step = 3
        self.header_label.config(
            text=f"படி 3/3 — சரிபார்ப்பு / Step 3/3 — Verification — {self.customer_name}"
        )
        self.status_label.config(
            text="இரண்டு பக்கங்களும் தயார். சரிபார்த்து சேமிக்கவும்.\nBoth pages ready. Confirm & Save.",
            fg=COLOR_PRIMARY,
        )
        self._clear_buttons()
        # show the back page (last captured) as the main preview; front is already saved to temp path
        if self.back_temp_path and PIL_AVAILABLE:
            self._show_image_file(self.back_temp_path)

        make_button(self.btn_row1, "⬅ பின் பக்கம் மாற்று / Redo Back Page", self.show_step_2,
                    bg="#888", width=26, height=1, font=(TAMIL_FONT_FAMILY, 10)).pack(side="left", padx=6)
        make_button(self.btn_row1, "✅ உறுதி & சேமி / Confirm & Save", self.save_documents,
                    bg=COLOR_SUCCESS, width=26, height=1, font=(TAMIL_FONT_FAMILY, 10)).pack(side="left", padx=6)

    def save_documents(self):
        if not self.front_temp_path or not self.back_temp_path:
            messagebox.showerror("தவறு / Error", "இரண்டு பக்கங்களும் தேவை.\nBoth pages are required.")
            return

        customer_folder = os.path.join(self.DOCS_FOLDER, str(self.customer_id))
        os.makedirs(customer_folder, exist_ok=True)
        front_dest = os.path.join(customer_folder, "front.jpg")
        back_dest = os.path.join(customer_folder, "back.jpg")

        try:
            shutil.copyfile(self.front_temp_path, front_dest)
            shutil.copyfile(self.back_temp_path, back_dest)
        except Exception as e:
            messagebox.showerror("தவறு / Error", f"Save பண்ண முடியவில்லை: {e}\nCould not save the files: {e}")
            return

        db.save_customer_documents(self.customer_id, front_dest, back_dest)
        messagebox.showinfo(
            "சரிபார்க்கப்பட்டது / Verified",
            f"{self.customer_name} - ID proof சேமிக்கப்பட்டது!\nID proof saved and marked as verified.\n\n{customer_folder}"
        )
        if self.on_saved:
            self.on_saved()
        self.close_window()

    # ---------- shared helpers ----------
    def _clear_buttons(self):
        for widget in self.btn_row1.winfo_children():
            widget.destroy()
        for widget in self.btn_row2.winfo_children():
            widget.destroy()

    def _show_placeholder(self, text):
        self.preview_label.configure(image="", text=text, fg="white", font=FONT_LABEL, compound="center")
        self.preview_label.image = None

    def _show_image_file(self, path):
        if not PIL_AVAILABLE:
            self.preview_label.configure(text="(Preview unavailable - Pillow not installed)", image="")
            return
        try:
            img = Image.open(path)
            img.thumbnail((480, 320))
            imgtk = ImageTk.PhotoImage(img)
            self.preview_label.configure(image=imgtk, text="")
            self.preview_label.image = imgtk
        except Exception:
            self.preview_label.configure(text="(Could not preview this image)", image="")

    def _show_next_button(self, next_step_fn):
        for widget in self.btn_row2.winfo_children():
            widget.destroy()
        make_button(self.btn_row2, "அடுத்து ➡ / Next", next_step_fn, bg=COLOR_ACCENT,
                    width=20, height=1, font=(TAMIL_FONT_FAMILY, 11)).pack()

    def _open_camera_capture(self, step_target):
        """Opens a small live-preview sub-window with a Capture button."""
        if not qr_utils.CAMERA_SUPPORT:
            messagebox.showwarning(
                "Camera Library இல்லை / Camera library missing",
                "opencv-python install ஆகலை. 'Choose File' option-ஐ use பண்ணுங்க.\n"
                "opencv-python is not installed. Please use 'Choose File' instead."
            )
            return

        cam = qr_utils.PlainCamera()
        if not cam.available:
            messagebox.showwarning(
                "Camera கிடைக்கவில்லை / Camera not found",
                "இந்த PC-ல் camera இல்லை அல்லது வேற app use பண்ணுது. 'Choose File' option-ஐ use பண்ணுங்க.\n"
                "No camera found on this PC. Please use 'Choose File' instead."
            )
            cam.release()
            return

        capture_win = tk.Toplevel(self)
        capture_win.title("📷 Capture ID Page")
        capture_win.geometry("520x460")
        capture_win.configure(bg=COLOR_BG)
        video_label = tk.Label(capture_win, bg="black")
        video_label.pack(padx=10, pady=10)

        state = {"closed": False}

        def update_preview():
            if state["closed"]:
                return
            frame = cam.read_frame()
            if frame is not None and PIL_AVAILABLE:
                import cv2
                rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
                img = Image.fromarray(rgb).resize((480, 360))
                imgtk = ImageTk.PhotoImage(image=img)
                video_label.imgtk = imgtk
                video_label.configure(image=imgtk)
            if not state["closed"]:
                capture_win.after(60, update_preview)

        def do_capture():
            frame = cam.read_frame()
            if frame is None:
                messagebox.showerror("தவறு / Error", "Capture பண்ண முடியவில்லை.\nCould not capture an image.")
                return
            os.makedirs("temp_captures", exist_ok=True)
            temp_path = os.path.join("temp_captures", f"capture_{self.customer_id}_{step_target}.jpg")
            cam.save_frame(frame, temp_path)
            if step_target == 1:
                self.front_temp_path = temp_path
            else:
                self.back_temp_path = temp_path
            state["closed"] = True
            cam.release()
            capture_win.destroy()
            self._show_image_file(temp_path)
            self._show_next_button(self.show_step_2 if step_target == 1 else self.show_step_3)

        def close_capture():
            state["closed"] = True
            cam.release()
            capture_win.destroy()

        capture_win.protocol("WM_DELETE_WINDOW", close_capture)
        btn_frame = tk.Frame(capture_win, bg=COLOR_BG)
        btn_frame.pack(pady=6)
        make_button(btn_frame, "📸 Capture", do_capture, bg=COLOR_SUCCESS, width=14, height=1).pack(side="left", padx=6)
        make_button(btn_frame, "❌ Cancel", close_capture, bg=COLOR_DANGER, width=14, height=1).pack(side="left", padx=6)

        update_preview()

    def close_window(self):
        self._closed = True
        self.destroy()


# ---------------------------------------------------------------------------
# CUSTOMER DETAILS WINDOW (shows profile + ID verification info/images)
# ---------------------------------------------------------------------------
class CustomerDetailsWindow(tk.Toplevel):
    """Read-only display of a customer's info and, if verified, their ID proof images."""

    def __init__(self, parent, customer_id):
        super().__init__(parent)
        customer = db.get_customer_by_id(customer_id)
        if not customer:
            self.destroy()
            return
        (cust_id, name, phone, address, credit, id_verified,
         front_path, back_path, verified_date) = customer

        self.title(f"👁 வாடிக்கையாளர் விவரம் / Customer Details — {name}")
        self.geometry("640x520")
        self.configure(bg=COLOR_BG)

        tk.Label(self, text=f"👤 {name}", font=(TAMIL_FONT_FAMILY, 16, "bold"),
                 bg=COLOR_BG, fg=COLOR_PRIMARY).pack(pady=(14, 4))

        info = tk.Frame(self, bg=COLOR_CARD, relief="ridge", bd=1)
        info.pack(fill="x", padx=20, pady=10)

        rows = [
            ("📞 போன் / Phone:", phone or "-"),
            ("🏠 முகவரி / Address:", address or "-"),
            ("💰 உதவி பாக்கி / Credit Due:", f"₹{credit:.2f}"),
            ("🪪 சரிபார்ப்பு நிலை / Verification Status:",
             "✅ Verified" if id_verified else "❌ Not Verified"),
            ("📅 சரிபார்த்த தேதி / Verified On:", verified_date or "-"),
        ]
        for i, (label, value) in enumerate(rows):
            tk.Label(info, text=label, font=FONT_LABEL, bg=COLOR_CARD, fg=COLOR_TEXT, anchor="w",
                     width=28).grid(row=i, column=0, sticky="w", padx=10, pady=6)
            tk.Label(info, text=value, font=(TAMIL_FONT_FAMILY, 11, "bold"), bg=COLOR_CARD,
                     fg=COLOR_PRIMARY if id_verified else COLOR_DANGER, anchor="w").grid(
                row=i, column=1, sticky="w", padx=10, pady=6)

        images_frame = tk.Frame(self, bg=COLOR_BG)
        images_frame.pack(fill="both", expand=True, padx=20, pady=10)

        if id_verified and front_path and back_path and PIL_AVAILABLE and os.path.exists(front_path) and os.path.exists(back_path):
            for title, path, side in (("முன் பக்கம் / Front", front_path, "left"),
                                       ("பின் பக்கம் / Back", back_path, "right")):
                col = tk.Frame(images_frame, bg=COLOR_BG)
                col.pack(side=side, expand=True, padx=10)
                tk.Label(col, text=title, font=FONT_LABEL, bg=COLOR_BG, fg=COLOR_PRIMARY).pack(pady=(0, 4))
                try:
                    img = Image.open(path)
                    img.thumbnail((260, 260))
                    imgtk = ImageTk.PhotoImage(img)
                    lbl = tk.Label(col, image=imgtk, bg="black")
                    lbl.image = imgtk  # keep reference
                    lbl.pack()
                except Exception:
                    tk.Label(col, text="(image load error)", bg=COLOR_BG, fg=COLOR_DANGER).pack()
        else:
            tk.Label(images_frame, text="இன்னும் ID proof சரிபார்க்கப்படவில்லை.\nID proof not verified yet.",
                     font=FONT_LABEL, bg=COLOR_BG, fg="#888").pack(pady=40)

        make_button(self, "❌ மூடு / Close", self.destroy, bg=COLOR_DANGER, width=14, height=1).pack(pady=12)


# ---------------------------------------------------------------------------
# CUSTOMERS PAGE
# ---------------------------------------------------------------------------
class CustomersPage(tk.Frame):
    def __init__(self, parent, controller):
        super().__init__(parent, bg=COLOR_BG)
        self.controller = controller

        header = tk.Frame(self, bg=COLOR_SUCCESS, height=60)
        header.pack(fill="x")
        make_button(header, "⬅ முகப்பு / Home", lambda: controller.show_frame("HomePage"),
                    bg="#1b5e20", width=14, height=1, font=FONT_LABEL).pack(side="left", padx=12, pady=12)
        tk.Label(header, text="👥 வாடிக்கையாளர்கள் / Customers", font=(TAMIL_FONT_FAMILY, 16, "bold"),
                  bg=COLOR_SUCCESS, fg="white").pack(side="left", padx=20)

        form = tk.LabelFrame(self, text="புதிய வாடிக்கையாளர் / Add Customer", font=FONT_LABEL, bg=COLOR_BG, fg=COLOR_PRIMARY)
        form.pack(fill="x", padx=20, pady=12)

        tk.Label(form, text="பெயர் / Name:", font=FONT_LABEL, bg=COLOR_BG).grid(row=0, column=0, padx=8, pady=8)
        self.name_entry = tk.Entry(form, font=FONT_LABEL, width=20)
        self.name_entry.grid(row=0, column=1, padx=8)

        tk.Label(form, text="போன் / Phone:", font=FONT_LABEL, bg=COLOR_BG).grid(row=0, column=2, padx=8)
        self.phone_entry = tk.Entry(form, font=FONT_LABEL, width=15)
        self.phone_entry.grid(row=0, column=3, padx=8)

        tk.Label(form, text="முகவரி / Address:", font=FONT_LABEL, bg=COLOR_BG).grid(row=0, column=4, padx=8)
        self.address_entry = tk.Entry(form, font=FONT_LABEL, width=20)
        self.address_entry.grid(row=0, column=5, padx=8)

        make_button(form, "💾 சேமி / Save", self.save_customer, bg=COLOR_SUCCESS, width=14, height=1).grid(row=0, column=6, padx=10)

        table_frame = tk.Frame(self, bg=COLOR_BG)
        table_frame.pack(fill="both", expand=True, padx=20, pady=10)
        columns = ("id", "name", "phone", "address", "credit", "verified")
        self.tree = ttk.Treeview(table_frame, columns=columns, show="headings", height=12)
        headers = {"id": "ID", "name": "பெயர்/Name", "phone": "போன்/Phone",
                   "address": "முகவரி/Address", "credit": "உதவி பாக்கி/Credit Due",
                   "verified": "ID Verified"}
        for col in columns:
            self.tree.heading(col, text=headers[col])
            self.tree.column(col, width=90 if col == "id" else 140, anchor="center")
        self.tree.pack(side="left", fill="both", expand=True)

        scrollbar = ttk.Scrollbar(table_frame, orient="vertical", command=self.tree.yview)
        scrollbar.pack(side="right", fill="y")
        self.tree.configure(yscrollcommand=scrollbar.set)

        btn_row = tk.Frame(self, bg=COLOR_BG)
        btn_row.pack(pady=(0, 10))
        make_button(btn_row, "📄 ID Proof Scan & Verify பண்ணு", self.open_verification, bg="#0078d4",
                    width=30, height=1, font=(TAMIL_FONT_FAMILY, 10)).pack(side="left", padx=6)
        make_button(btn_row, "👁 விவரம் பார் / View Details", self.open_details, bg=COLOR_PRIMARY,
                    width=26, height=1, font=(TAMIL_FONT_FAMILY, 10)).pack(side="left", padx=6)

    def on_show(self):
        self.refresh_table()

    def refresh_table(self):
        for row in self.tree.get_children():
            self.tree.delete(row)
        for cust in db.get_customers():
            customer_id, name, phone, address, credit, id_verified, front_path, back_path, verified_date = cust
            verified_text = "✅ Verified" if id_verified else "❌ Not Verified"
            self.tree.insert("", "end", values=(customer_id, name, phone, address, f"{credit:.2f}", verified_text))

    def save_customer(self):
        name = self.name_entry.get().strip()
        phone = self.phone_entry.get().strip()
        address = self.address_entry.get().strip()
        if not name:
            messagebox.showerror("தவறு / Error", "பெயர் கட்டாயம்.\nName is required.")
            return
        db.add_customer(name, phone, address)
        self.name_entry.delete(0, tk.END)
        self.phone_entry.delete(0, tk.END)
        self.address_entry.delete(0, tk.END)
        self.refresh_table()

    def open_verification(self):
        selected = self.tree.selection()
        if not selected:
            messagebox.showwarning("வாடிக்கையாளர் தேர்வு / Select a customer",
                                    "முதலில் table-ல் ஒரு வாடிக்கையாளரை தேர்வு செய்யவும்.\nSelect a customer from the table first.")
            return
        values = self.tree.item(selected[0])["values"]
        customer_id, customer_name = values[0], values[1]
        DocumentVerificationWindow(self, customer_id, customer_name, on_saved=self.refresh_table)

    def open_details(self):
        selected = self.tree.selection()
        if not selected:
            messagebox.showwarning("வாடிக்கையாளர் தேர்வு / Select a customer",
                                    "முதலில் table-ல் ஒரு வாடிக்கையாளரை தேர்வு செய்யவும்.\nSelect a customer from the table first.")
            return
        customer_id = self.tree.item(selected[0])["values"][0]
        CustomerDetailsWindow(self, customer_id)


# ---------------------------------------------------------------------------
# REPORTS PAGE
# ---------------------------------------------------------------------------
class ReportsPage(tk.Frame):
    def __init__(self, parent, controller):
        super().__init__(parent, bg=COLOR_BG)
        self.controller = controller

        header = tk.Frame(self, bg="#0078d4", height=60)
        header.pack(fill="x")
        make_button(header, "⬅ முகப்பு / Home", lambda: controller.show_frame("HomePage"),
                    bg="#005a9e", width=14, height=1, font=FONT_LABEL).pack(side="left", padx=12, pady=12)
        tk.Label(header, text="📊 விற்பனை அறிக்கை / Sales Reports", font=(TAMIL_FONT_FAMILY, 16, "bold"),
                  bg="#0078d4", fg="white").pack(side="left", padx=20)

        table_frame = tk.Frame(self, bg=COLOR_BG)
        table_frame.pack(fill="both", expand=True, padx=20, pady=14)
        columns = ("bill_no", "customer", "total", "discount", "grand_total", "payment", "date")
        self.tree = ttk.Treeview(table_frame, columns=columns, show="headings", height=15)
        headers = {
            "bill_no": "பில் எண்/Bill No", "customer": "வாடிக்கையாளர்/Customer",
            "total": "மொத்தம்/Total", "discount": "தள்ளுபடி/Discount",
            "grand_total": "இறுதி தொகை/Grand Total", "payment": "பணம்/Payment", "date": "தேதி/Date",
        }
        for col in columns:
            self.tree.heading(col, text=headers[col])
            self.tree.column(col, width=130, anchor="center")
        self.tree.pack(side="left", fill="both", expand=True)

        scrollbar = ttk.Scrollbar(table_frame, orient="vertical", command=self.tree.yview)
        scrollbar.pack(side="right", fill="y")
        self.tree.configure(yscrollcommand=scrollbar.set)

        self.summary_label = tk.Label(self, text="மொத்த விற்பனை / Total Sales: ₹0.00",
                                       font=(TAMIL_FONT_FAMILY, 14, "bold"), bg=COLOR_BG, fg=COLOR_PRIMARY)
        self.summary_label.pack(pady=10)

    def on_show(self):
        self.refresh_table()

    def refresh_table(self):
        for row in self.tree.get_children():
            self.tree.delete(row)
        bills = db.get_bills()
        total_sales = 0
        for b in bills:
            _id, bill_no, customer_name, total, discount, grand_total, payment_mode, bill_date = b
            self.tree.insert("", "end", values=(bill_no, customer_name, f"{total:.2f}", f"{discount:.2f}",
                                                 f"{grand_total:.2f}", payment_mode, bill_date))
            total_sales += grand_total
        self.summary_label.config(text=f"மொத்த விற்பனை / Total Sales: ₹{total_sales:.2f}  |  பில்கள்/Bills: {len(bills)}")


if __name__ == "__main__":
    app = TextileBillingApp()
    app.mainloop()
