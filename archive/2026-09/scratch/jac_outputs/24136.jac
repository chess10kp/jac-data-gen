"""Selects a specific mysql user and returns true if it exists."""
def select_user(user: str) -> str {
    return "SELECT user FROM mysql.user WHERE user = '" + user + "'";
}