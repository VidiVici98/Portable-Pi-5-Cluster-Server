from flask_login import UserMixin
import sqlite3
from pathlib import Path

DB_PATH = Path(__file__).resolve().parents[1] / "catwalk.db"

class User(UserMixin):
    def __init__(self, id, username, display_name, role):
        self.id = id
        self.username = username
        self.display_name = display_name
        self.role = role


def admin_exists():
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()

    cursor.execute(
        "SELECT 1 FROM users WHERE role = 'admin' LIMIT 1"
    )
    exists = cursor.fetchone() is not None

    conn.close()
    return exists
import hashlib
import os

def hash_password(password: str) -> str:
    salt = os.urandom(16)
    hashed = hashlib.pbkdf2_hmac(
        "sha256",
        password.encode("utf-8"),
        salt,
        100_000
    )
    return salt.hex() + ":" + hashed.hex()


def create_admin(username, password):
    password_hash = hash_password(password)

    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()

    cursor.execute(
        """
        INSERT INTO users (username, display_name, password_hash, role)
        VALUES (?, ?, ?, 'admin')
        """,
        (username, username, password_hash)
    )

    conn.commit()
    conn.close()

def get_user_by_username(username):
    conn = sqlite3.connect("web/catwalk.db")
    conn.row_factory = sqlite3.Row
    cur = conn.cursor()
    cur.execute("SELECT * FROM users WHERE username = ?", (username,))
    row = cur.fetchone()
    conn.close()
    return row
