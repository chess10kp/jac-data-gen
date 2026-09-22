"""Check if the line has a url or song name."""
def check_type(line: str) -> str {
    'url' if 'http' in line else 'name'
}