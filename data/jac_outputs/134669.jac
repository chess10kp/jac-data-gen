"""
    Performs a dictionary lookup.
    """
def key(d: Any, key_name: Any) -> object {
    try {
        return d[key_name];
    } except KeyError {
        return 0;
    }
}