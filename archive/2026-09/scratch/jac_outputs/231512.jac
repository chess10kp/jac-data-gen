"""Convert a host, port and command to a url."""
def _to_url(host: str, port: int, cmd: str) -> str {
    "http://{:s}:{:d}/{:s}".format(host, port, cmd)
}