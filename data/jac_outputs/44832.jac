"""
    http://stackoverflow.com/questions/35817/how-to-escape-os-system-calls-in-python
    """
def _shellquote(s: str) -> str {
    return "'" + s.replace("'", "'\\''") + "'";
}