"""Dump Response of required attribute not exist exception."""
def _ArgsException(key: str) -> str {
    r"""{"return": "Missed required attribute: %s", "code": "Failed"}""" % key
}