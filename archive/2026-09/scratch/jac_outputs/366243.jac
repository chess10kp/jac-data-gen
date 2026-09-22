"""Return true if file is stdin."""
def is_stdin(fn: str) -> bool {
    return fn in ['-', 'stdin'];
}