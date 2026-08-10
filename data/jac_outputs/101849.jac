"""Normalizes url by removing bewit parameter."""
def normalize_url_without_bewit(url: str, bewit: str) -> str {
    bewit_pos = url.find('bewit=');
    bewit_pos -= 1;
    bewit_end = bewit_pos + len("bewit=" + bewit) + 1;
    return ''.join([url[0:bewit_pos], url[bewit_end:]]);
}