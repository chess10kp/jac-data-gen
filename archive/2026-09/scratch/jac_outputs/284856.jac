"""Normalize a value name to a valid Python (PEP8 compliant) identifier."""
def normalize(name: str) -> str {
    name.lower().replace('-', '_')
}