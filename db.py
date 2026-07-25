"""
db.py
-----
Database layer for Textile Shop Billing Software.
Uses SQLite (built into Python - no extra install needed).
The database file (textile_billing.db) is created automatically
in the same folder as the app, next to the .exe.
"""

import sqlite3
import os
from datetime import datetime

DB_NAME = "textile_billing.db"


def get_connection():
    conn = sqlite3.connect(DB_NAME)
    conn.execute("PRAGMA foreign_keys = ON")
    return conn


def init_db():
    """Create all tables if they don't already exist. Safe to call every startup."""
    conn = get_connection()
    c = conn.cursor()

    c.execute("""
        CREATE TABLE IF NOT EXISTS products (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            design_no TEXT,
            color TEXT,
            unit TEXT DEFAULT 'Piece',
            price REAL NOT NULL DEFAULT 0,
            stock REAL NOT NULL DEFAULT 0,
            qr_code TEXT
        )
    """)
    # Safe upgrade for databases created before qr_code existed
    c.execute("PRAGMA table_info(products)")
    existing_cols = [row[1] for row in c.fetchall()]
    if "qr_code" not in existing_cols:
        c.execute("ALTER TABLE products ADD COLUMN qr_code TEXT")

    c.execute("""
        CREATE TABLE IF NOT EXISTS customers (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            phone TEXT,
            address TEXT,
            credit_balance REAL DEFAULT 0,
            id_verified INTEGER DEFAULT 0,
            id_front_path TEXT,
            id_back_path TEXT,
            id_verified_date TEXT
        )
    """)
    c.execute("PRAGMA table_info(customers)")
    existing_customer_cols = [row[1] for row in c.fetchall()]
    for col_name, col_type in [("id_verified", "INTEGER DEFAULT 0"), ("id_front_path", "TEXT"),
                                ("id_back_path", "TEXT"), ("id_verified_date", "TEXT")]:
        if col_name not in existing_customer_cols:
            c.execute(f"ALTER TABLE customers ADD COLUMN {col_name} {col_type}")

    c.execute("""
        CREATE TABLE IF NOT EXISTS bills (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            bill_no TEXT NOT NULL,
            customer_id INTEGER,
            customer_name TEXT,
            total REAL NOT NULL,
            discount REAL DEFAULT 0,
            grand_total REAL NOT NULL,
            payment_mode TEXT,
            bill_date TEXT,
            FOREIGN KEY (customer_id) REFERENCES customers(id)
        )
    """)

    c.execute("""
        CREATE TABLE IF NOT EXISTS bill_items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            bill_id INTEGER NOT NULL,
            product_id INTEGER,
            product_name TEXT,
            qty REAL,
            unit TEXT,
            rate REAL,
            subtotal REAL,
            FOREIGN KEY (bill_id) REFERENCES bills(id),
            FOREIGN KEY (product_id) REFERENCES products(id)
        )
    """)

    conn.commit()
    conn.close()


# ---------------- PRODUCTS ----------------

def add_product(name, design_no, color, unit, price, stock, qr_code=None):
    conn = get_connection()
    c = conn.cursor()
    c.execute(
        "INSERT INTO products (name, design_no, color, unit, price, stock, qr_code) VALUES (?,?,?,?,?,?,?)",
        (name, design_no, color, unit, price, stock, qr_code),
    )
    new_id = c.lastrowid
    # If no custom QR/barcode value was given, default the code to the product's own ID
    # so every product always has a scannable code, even without a printed barcode.
    if not qr_code:
        c.execute("UPDATE products SET qr_code=? WHERE id=?", (str(new_id), new_id))
    conn.commit()
    conn.close()
    return new_id


def update_product(product_id, name, design_no, color, unit, price, stock, qr_code=None):
    conn = get_connection()
    c = conn.cursor()
    if qr_code:
        c.execute(
            """UPDATE products SET name=?, design_no=?, color=?, unit=?, price=?, stock=?, qr_code=?
               WHERE id=?""",
            (name, design_no, color, unit, price, stock, qr_code, product_id),
        )
    else:
        c.execute(
            """UPDATE products SET name=?, design_no=?, color=?, unit=?, price=?, stock=?
               WHERE id=?""",
            (name, design_no, color, unit, price, stock, product_id),
        )
    conn.commit()
    conn.close()


def delete_product(product_id):
    conn = get_connection()
    conn.execute("DELETE FROM products WHERE id=?", (product_id,))
    conn.commit()
    conn.close()


def get_products(search=""):
    conn = get_connection()
    c = conn.cursor()
    if search:
        like = f"%{search}%"
        c.execute(
            """SELECT id, name, design_no, color, unit, price, stock, qr_code FROM products
               WHERE name LIKE ? OR design_no LIKE ? OR color LIKE ?
               ORDER BY name""",
            (like, like, like),
        )
    else:
        c.execute("SELECT id, name, design_no, color, unit, price, stock, qr_code FROM products ORDER BY name")
    rows = c.fetchall()
    conn.close()
    return rows


def get_product_by_id(product_id):
    conn = get_connection()
    c = conn.cursor()
    c.execute("SELECT id, name, design_no, color, unit, price, stock, qr_code FROM products WHERE id=?", (product_id,))
    row = c.fetchone()
    conn.close()
    return row


def get_product_by_code(code):
    """
    Looks up a product by its scanned QR/barcode value.
    Falls back to matching by product ID, so a QR containing just
    the raw ID (e.g. "7") or a custom format (e.g. "PID:7") both work.
    Returns None if nothing matches.
    """
    code = (code or "").strip()
    if not code:
        return None
    # Accept formats like "PID:7" by pulling out the trailing number
    raw_code = code
    if ":" in code:
        raw_code = code.split(":")[-1].strip()

    conn = get_connection()
    c = conn.cursor()
    c.execute("SELECT id, name, design_no, color, unit, price, stock, qr_code FROM products WHERE qr_code=?", (code,))
    row = c.fetchone()
    if not row:
        c.execute("SELECT id, name, design_no, color, unit, price, stock, qr_code FROM products WHERE qr_code=?", (raw_code,))
        row = c.fetchone()
    if not row and raw_code.isdigit():
        c.execute("SELECT id, name, design_no, color, unit, price, stock, qr_code FROM products WHERE id=?", (int(raw_code),))
        row = c.fetchone()
    conn.close()
    return row


def adjust_stock(product_id, qty_change):
    """qty_change is negative for a sale, positive for a return/restock."""
    conn = get_connection()
    conn.execute("UPDATE products SET stock = stock + ? WHERE id=?", (qty_change, product_id))
    conn.commit()
    conn.close()


# ---------------- CUSTOMERS ----------------

def add_customer(name, phone, address):
    conn = get_connection()
    conn.execute(
        "INSERT INTO customers (name, phone, address, credit_balance) VALUES (?,?,?,0)",
        (name, phone, address),
    )
    conn.commit()
    conn.close()


def get_customers(search=""):
    conn = get_connection()
    c = conn.cursor()
    if search:
        like = f"%{search}%"
        c.execute(
            """SELECT id, name, phone, address, credit_balance, id_verified, id_front_path, id_back_path, id_verified_date
               FROM customers WHERE name LIKE ? OR phone LIKE ? ORDER BY name""",
            (like, like),
        )
    else:
        c.execute(
            """SELECT id, name, phone, address, credit_balance, id_verified, id_front_path, id_back_path, id_verified_date
               FROM customers ORDER BY name"""
        )
    rows = c.fetchall()
    conn.close()
    return rows


def get_customer_by_id(customer_id):
    conn = get_connection()
    c = conn.cursor()
    c.execute(
        """SELECT id, name, phone, address, credit_balance, id_verified, id_front_path, id_back_path, id_verified_date
           FROM customers WHERE id=?""",
        (customer_id,),
    )
    row = c.fetchone()
    conn.close()
    return row


def save_customer_documents(customer_id, front_path, back_path):
    """Marks a customer's ID proof as verified, stores the saved image paths and the verification timestamp."""
    from datetime import datetime
    verified_date = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    conn = get_connection()
    conn.execute(
        "UPDATE customers SET id_verified=1, id_front_path=?, id_back_path=?, id_verified_date=? WHERE id=?",
        (front_path, back_path, verified_date, customer_id),
    )
    conn.commit()
    conn.close()


def update_customer_credit(customer_id, amount_change):
    conn = get_connection()
    conn.execute("UPDATE customers SET credit_balance = credit_balance + ? WHERE id=?", (amount_change, customer_id))
    conn.commit()
    conn.close()


# ---------------- BILLING ----------------

def generate_bill_no():
    """Simple auto bill number like TS-20260724-0001"""
    conn = get_connection()
    c = conn.cursor()
    today_str = datetime.now().strftime("%Y%m%d")
    c.execute("SELECT COUNT(*) FROM bills WHERE bill_no LIKE ?", (f"TS-{today_str}-%",))
    count = c.fetchone()[0]
    conn.close()
    return f"TS-{today_str}-{count + 1:04d}"


def create_bill(customer_id, customer_name, cart_items, discount, payment_mode):
    """
    cart_items: list of dicts:
        {product_id, name, qty, unit, rate, subtotal}
    Saves the bill, saves each line item, and deducts stock.
    Returns (bill_id, bill_no, grand_total)
    """
    total = sum(item["subtotal"] for item in cart_items)
    grand_total = round(total - discount, 2)
    bill_no = generate_bill_no()
    bill_date = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    conn = get_connection()
    c = conn.cursor()
    c.execute(
        """INSERT INTO bills (bill_no, customer_id, customer_name, total, discount, grand_total, payment_mode, bill_date)
           VALUES (?,?,?,?,?,?,?,?)""",
        (bill_no, customer_id, customer_name, total, discount, grand_total, payment_mode, bill_date),
    )
    bill_id = c.lastrowid

    for item in cart_items:
        c.execute(
            """INSERT INTO bill_items (bill_id, product_id, product_name, qty, unit, rate, subtotal)
               VALUES (?,?,?,?,?,?,?)""",
            (bill_id, item["product_id"], item["name"], item["qty"], item["unit"], item["rate"], item["subtotal"]),
        )
        # Deduct stock
        if item["product_id"] is not None:
            c.execute("UPDATE products SET stock = stock - ? WHERE id=?", (item["qty"], item["product_id"]))

    # If credit payment, add to customer's khata balance
    if payment_mode == "Credit / உதவி" and customer_id is not None:
        c.execute("UPDATE customers SET credit_balance = credit_balance + ? WHERE id=?", (grand_total, customer_id))

    conn.commit()
    conn.close()
    return bill_id, bill_no, grand_total


def get_bills(date_filter=None):
    conn = get_connection()
    c = conn.cursor()
    if date_filter:
        c.execute(
            "SELECT id, bill_no, customer_name, total, discount, grand_total, payment_mode, bill_date FROM bills WHERE bill_date LIKE ? ORDER BY id DESC",
            (f"{date_filter}%",),
        )
    else:
        c.execute("SELECT id, bill_no, customer_name, total, discount, grand_total, payment_mode, bill_date FROM bills ORDER BY id DESC")
    rows = c.fetchall()
    conn.close()
    return rows


def get_bill_items(bill_id):
    conn = get_connection()
    c = conn.cursor()
    c.execute("SELECT product_name, qty, unit, rate, subtotal FROM bill_items WHERE bill_id=?", (bill_id,))
    rows = c.fetchall()
    conn.close()
    return rows


def save_receipt_text(bill_id, bill_no, customer_name, items, discount, grand_total, payment_mode, bill_date):
    """Saves a simple, printable text receipt into the 'bills' folder."""
    os.makedirs("bills", exist_ok=True)
    path = os.path.join("bills", f"{bill_no}.txt")
    lines = []
    lines.append("      ஸ்ரீ டெக்ஸ்டைல்ஸ் / SHOP NAME HERE")
    lines.append("=" * 42)
    lines.append(f"பில் எண் / Bill No : {bill_no}")
    lines.append(f"தேதி / Date        : {bill_date}")
    lines.append(f"வாடிக்கையாளர் / Customer : {customer_name or 'Walk-in'}")
    lines.append("-" * 42)
    lines.append(f"{'பொருள்/Item':<18}{'Qty':>5}{'Rate':>8}{'Amt':>9}")
    lines.append("-" * 42)
    for name, qty, unit, rate, subtotal in items:
        short_name = (name[:16] + "..") if len(name) > 18 else name
        lines.append(f"{short_name:<18}{qty:>5.1f}{rate:>8.2f}{subtotal:>9.2f}")
    lines.append("-" * 42)
    lines.append(f"{'தள்ளுபடி / Discount':<27}{discount:>15.2f}")
    lines.append(f"{'மொத்தம் / GRAND TOTAL':<27}{grand_total:>15.2f}")
    lines.append(f"பணம் செலுத்தும் முறை / Payment : {payment_mode}")
    lines.append("=" * 42)
    lines.append("நன்றி! மீண்டும் வருக!")
    lines.append("Thank you! Visit Again!")

    with open(path, "w", encoding="utf-8") as f:
        f.write("\n".join(lines))
    return path
