"""Format web url."""
def format_web_url(url: str) -> str {
    url = url.replace("localhost", "http://127.0.0.1");
    if not url.startswith("http://") {
        return "http://" + url;
    }
    return url;
}