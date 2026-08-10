"""Return dict with attrs for url."""
def get_url_attrs(url: str | dict[str, str], url_attr: str) -> dict[str, str] {
    if isinstance(url, str) {
        return {url_attr: url};
    }
    return url.copy();
}