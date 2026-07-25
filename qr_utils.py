"""
qr_utils.py
-----------
Everything related to QR codes:
 - generating a QR code image for a product (to print & stick on the item/shelf)
 - reading QR codes live from a webcam (used on the Billing screen)

Needs these extra libraries (already listed in requirements.txt):
    pip install qrcode pillow opencv-python pyzbar
"""

import os
import qrcode

try:
    import cv2
    from pyzbar.pyzbar import decode as zbar_decode
    CAMERA_SUPPORT = True
except ImportError:
    CAMERA_SUPPORT = False


QR_FOLDER = "qr_codes"


def generate_qr_image(code_value, product_name=""):
    """
    Creates a QR code PNG for the given code value (usually the product's id
    or a custom barcode string) and saves it in the qr_codes/ folder.
    Returns the file path.
    """
    os.makedirs(QR_FOLDER, exist_ok=True)
    safe_name = "".join(ch for ch in (product_name or "product") if ch.isalnum() or ch in (" ", "_", "-")).strip()
    safe_name = safe_name.replace(" ", "_") or "product"
    path = os.path.join(QR_FOLDER, f"{code_value}_{safe_name}.png")

    qr = qrcode.QRCode(box_size=10, border=4)
    qr.add_data(str(code_value))
    qr.make(fit=True)
    img = qr.make_image(fill_color="black", back_color="white")
    img.save(path)
    return path


def generate_qr_for_all(products):
    """
    products: list of rows (id, name, design_no, color, unit, price, stock, qr_code)
    Generates one QR image per product. Returns the folder path.
    """
    for p in products:
        product_id, name = p[0], p[1]
        code_value = p[7] or str(product_id)
        generate_qr_image(code_value, name)
    return os.path.abspath(QR_FOLDER)


class PlainCamera:
    """
    A camera wrapper (no QR decoding) used for photographing ID proof
    documents (Aadhaar / Voter ID) during customer verification.
    """

    def __init__(self, camera_index=0):
        self.available = False
        self.cap = None
        if not CAMERA_SUPPORT:
            return
        try:
            self.cap = cv2.VideoCapture(camera_index)
            self.available = self.cap is not None and self.cap.isOpened()
        except Exception:
            self.available = False

    def read_frame(self):
        """Returns the raw BGR frame, or None if the camera isn't available."""
        if not self.available:
            return None
        ok, frame = self.cap.read()
        if not ok:
            return None
        return frame

    def save_frame(self, frame, path):
        """Saves a captured frame (BGR numpy array) to disk as a JPG."""
        cv2.imwrite(path, frame)

    def release(self):
        if self.cap is not None:
            self.cap.release()


class CameraQRScanner:
    """
    Small wrapper around OpenCV so the Billing screen can grab one frame
    at a time (non-blocking) and check it for a QR code.
    Usage:
        scanner = CameraQRScanner()
        if scanner.available:
            frame, code = scanner.read_frame()
        scanner.release()
    """

    def __init__(self, camera_index=0):
        self.available = False
        self.cap = None
        if not CAMERA_SUPPORT:
            return
        try:
            self.cap = cv2.VideoCapture(camera_index)
            self.available = self.cap is not None and self.cap.isOpened()
        except Exception:
            self.available = False

    def read_frame(self):
        """Returns (frame_bgr, decoded_code_or_None). frame_bgr is None if read failed."""
        if not self.available:
            return None, None
        ok, frame = self.cap.read()
        if not ok:
            return None, None
        code_value = None
        try:
            results = zbar_decode(frame)
            if results:
                code_value = results[0].data.decode("utf-8")
                # Draw a box around the detected QR so the user gets visual feedback
                points = results[0].polygon
                if points and len(points) >= 4:
                    import numpy as np
                    pts = np.array([(p.x, p.y) for p in points], dtype=int)
                    cv2.polylines(frame, [pts], True, (0, 255, 0), 3)
        except Exception:
            pass
        return frame, code_value

    def release(self):
        if self.cap is not None:
            self.cap.release()
