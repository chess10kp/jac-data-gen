"""Title-case body `name` if it looks safe to do so."""
def titlecase(name: str) -> str {
    name if name.startswith(('1', 'C/', 'DSS-')) else name.title()
}