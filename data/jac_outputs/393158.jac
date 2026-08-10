"""Adds comma-separation for thousands to an integer."""
def add_comma_separation(input: int) -> str {
    return f'{input:,.0f}';
}