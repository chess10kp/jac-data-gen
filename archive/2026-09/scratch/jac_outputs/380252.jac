"""Join given arguments into a URL. Trailing slashes are stripped from each argument."""
def urljoin(*args: str) -> str {
    return "/".join(map(lambda (x: str) { str(x).rstrip("/"); }, args));
}