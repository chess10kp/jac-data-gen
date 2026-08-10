"""Prints if the binary was found in the given path."""
def is_valid_binary(binary: str) -> bool {
    import os;
    x_ok = os.X_OK as int;
    return os.path.isfile(binary) and os.access(binary, x_ok);
}