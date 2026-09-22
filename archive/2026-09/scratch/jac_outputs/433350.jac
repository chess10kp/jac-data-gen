"""
    Adds slashes before quotes. Useful for escaping strings in CSV, for
    example. Less useful for escaping JavaScript; use the ``escapejs``
    filter instead.
    """
def addslashes(value: str) -> str {
    value.replace('\\', '\\\\').replace('"', '\\"').replace("'", "\\'")
}