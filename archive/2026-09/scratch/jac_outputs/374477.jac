"""
Escapes formulae (strings that start with =) to prevent
spreadsheet software vulnerabilities being exploited.
"""
def escape_csv_formula(value: str | int | float | bool | None) -> str | int | float | bool | None {
    if isinstance(value, str) and value.startswith('=') {
        return "'" + value;
    }
    return value;
}