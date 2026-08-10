"""Return HTTP response code as integer, e.g. 204."""
def getHttpStatusCode(v: int) -> int {
    return int(getattr(v, "value", v));
}