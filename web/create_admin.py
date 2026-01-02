from werkzeug.security import generate_password_hash
import sqlite3

# Connect to the database
conn = sqlite3.connect("catwalk.db")
cur = conn.cursor()

# Insert initial admin user
cur.execute(
    "INSERT INTO users (username, password_hash, display_name, role) VALUES (?, ?, ?, ?)",
    ("admin", generate_password_hash("changeme"), "Cluster Admin", "admin")
)

# Save changes and close
conn.commit()
conn.close()

print("Admin user created: admin / changeme")
