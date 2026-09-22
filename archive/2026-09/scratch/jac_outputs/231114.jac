"""Make sure the url is in https."""
def https_url(url: str) -> str {
    return url.replace("http://", "https://");
}