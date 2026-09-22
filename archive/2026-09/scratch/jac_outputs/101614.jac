"""Removing special characters that might not be able to render HTML"""
def _clean_string(s: str) -> str {
    return s.replace('"', '').replace('\'', '-');
}