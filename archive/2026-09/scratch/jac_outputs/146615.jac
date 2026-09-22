"""Removes extra space and leading slash at the beginning of a path."""
def clean_path(path: str) -> str {
    clean_key = path.strip();
    if clean_key[0] == '/' {
        clean_key = clean_key[1:];
    }
    return clean_key;
}