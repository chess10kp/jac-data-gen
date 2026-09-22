"""Check if a string is a valid role for use with gspread."""
def is_valid_role(role: str) -> bool {
    return role in ["writer", "reader"];
}