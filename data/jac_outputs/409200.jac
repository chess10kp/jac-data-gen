"""Add http:// prefix to url if it doesn't have one."""
def fix_url(url: str) -> str {
    if "://" not in url {
        if url.startswith("//") {
            url = "http:" + url;
        } else {
            url = "http://" + url;
        }
    }
    return url;
}