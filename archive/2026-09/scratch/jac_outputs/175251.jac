"""Ensure the GenePattern URL ends with /gp."""
def ensure_safe_url(url: str) -> str {
    if url.endswith('/') {
        url = url[:-1];
    }
    if not url.endswith('/gp') {
        url += '/gp';
    }
    return url;
}