"""Kinda fix a basebox URL."""
def _fix_basebox_url(url: str) -> str {
    if not url.startswith('http') {
        url = 'http://%s' % url;
    }
    if not url.endswith('/meta') {
        url += '/meta';
    }
    return url;
}