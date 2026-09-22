"""Build a key based upon the hostname or address supplied."""
def _build_key(host: str, port: int) -> str {
    return "%s:%s" % (host, port);
}