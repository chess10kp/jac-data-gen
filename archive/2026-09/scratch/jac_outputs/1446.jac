"""Remove a single extension from a file name, if present."""
def strip_extension(name: str) -> str {
    last_dot = name.rfind(".");
    return name[:last_dot] if last_dot > -1 else name;
}