from flask import (
    Blueprint,
    render_template,
    request,
    redirect,
    url_for,
    flash,
    abort,
    current_app
)
from flask_login import login_user, logout_user
from werkzeug.security import check_password_hash
from pathlib import Path
import sqlite3

from web.models.user import User, admin_exists, create_admin

auth_bp = Blueprint("auth", __name__)

DB_PATH = Path(__file__).resolve().parents[1] / "catwalk.db"


@auth_bp.route("/login", methods=["GET", "POST"])
def login():
    # ---------- POST: attempt login ----------
    if request.method == "POST":
        username = request.form.get("username")
        password = request.form.get("password")

        conn = sqlite3.connect(DB_PATH)
        cur = conn.cursor()
        cur.execute(
            """
            SELECT id, username, password_hash, display_name, role
            FROM users
            WHERE username = ?
            """,
            (username,)
        )
        row = cur.fetchone()
        conn.close()

        if row and check_password_hash(row[2], password):
            user = User(row[0], row[1], row[3], row[4])
            login_user(user)
            return redirect(url_for("dashboard.index"))

        flash("Invalid credentials")

    # ---------- GET (or failed POST): render login ----------
    system_state = "UNINITIALIZED" if not admin_exists() else "READY"

    return render_template(
        "login.html",
        system_state=system_state
    )


@auth_bp.route("/logout")
def logout():
    logout_user()
    return redirect(url_for("auth.login"))


@auth_bp.route("/bootstrap_admin", methods=["POST"])
def bootstrap_admin():
    if admin_exists():
        abort(403)

    username = request.form.get("admin_username")
    password = request.form.get("admin_password")
    confirm = request.form.get("admin_password_confirm")

    if not username or not password:
        return render_template(
            "login.html",
            system_state="UNINITIALIZED",
            error="All fields are required."
        )

    if password != confirm:
        return render_template(
            "login.html",
            system_state="UNINITIALIZED",
            error="Passwords do not match."
        )

    create_admin(username, password)

    current_app.logger.warning(
        "Bootstrap admin created from %s", request.remote_addr
    )

    return redirect(url_for("auth.login"))
