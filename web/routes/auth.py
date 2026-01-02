from flask import Blueprint, render_template, request, redirect, url_for, flash
from flask_login import login_user, logout_user
from werkzeug.security import check_password_hash
import sqlite3
from web.models.user import User

auth_bp = Blueprint("auth", __name__)

@auth_bp.route("/login", methods=["GET", "POST"])
def login():
    if request.method == "POST":
        username = request.form["username"]
        password = request.form["password"]

        # Connect to SQLite database
        conn = sqlite3.connect("web/catwalk.db")
        cur = conn.cursor()
        cur.execute(
            "SELECT id, username, password_hash, display_name, role FROM users WHERE username = ?",
            (username,)
        )
        row = cur.fetchone()
        conn.close()

        if row and check_password_hash(row[2], password):
            # create a User object
            user = User(row[0], row[1], row[3], row[4])
            login_user(user)  # Flask-Login: starts the session
            return redirect(url_for("dashboard.index"))  # redirect to dashboard

        flash("Invalid credentials")
    return render_template("login.html")


@auth_bp.route("/logout")
def logout():
    logout_user()
    return redirect(url_for("auth.login"))
