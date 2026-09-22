"""Strip URL of protocol info and ending slashes
    """
def canonical_url(url: str) -> str {
    url = url.lower();
    if url.startswith("http://") {
        url = url[7:];
    }
    if url.startswith("https://") {
        url = url[8:];
    }
    if url.startswith("www.") {
        url = url[4:];
    }
    if url.endswith("/") {
        url = url[:-1];
    }
    return url;
}