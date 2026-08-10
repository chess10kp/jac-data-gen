"""
    Replaces "/" characters with "-" to
    """
def name_normalize(name: Any) -> object {
    if (name is None) {
        return name;
    }
    return name.replace("/", "-");
}