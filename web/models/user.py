from flask_login import UserMixin

class User(UserMixin):
    def __init__(self, id, username, display_name, role):
        self.id = id
        self.username = username
        self.display_name = display_name
        self.role = role
