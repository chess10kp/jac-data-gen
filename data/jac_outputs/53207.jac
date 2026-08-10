"""Uppercase, stripped, no repeated interior whitespace."""
def _name_as_key(name: str) -> str {
    name = name.upper().strip();
    while '  ' in name {
        name = name.replace('  ', ' ');
    }
    return name;
}