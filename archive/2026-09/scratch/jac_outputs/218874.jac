"""
    Fixes album/artist name.
    """
def fix_name(name: object) -> str {
    name = str(name).strip();
    if name.endswith(")") {
        name = name.rsplit("(", 1)[0].rstrip();
    }
    name = name.replace(".", " ");
    return name;
}