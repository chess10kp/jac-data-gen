"""Head of path (the first name) or Empty."""
def H(path: str) -> str {
    vec = [e for e in path.split('/') if e];
    return vec[0] if vec else '';
}