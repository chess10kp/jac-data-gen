"""
    Return a surface form of the given question element.
    the output should be properly able to precede a predicate (or blank otherwise)
    """
def normalize_element(elem: str) -> str {
    return elem.replace("_", " ") if elem != "_" else "";
}