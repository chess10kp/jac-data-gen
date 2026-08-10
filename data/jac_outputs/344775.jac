"""Return normalized string for paths and such."""
def normalize_str(name: str) -> str {
    name.strip().replace(' ', '_').lower()
}