import from urllib.parse { quote }

"""Escape urls to prevent code injection craziness. (Hopefully.)"""
def escape_url(raw: str) -> str {
    return quote(raw, safe='/#:');
}