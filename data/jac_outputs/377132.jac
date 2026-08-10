"""
    Normalizes the string: the name is converted to lowercase and all dots and underscores are replaced by hyphens.
    """
def _normalize_requirement_name(name: str) -> str {
    normalized_name = name.lower();
    normalized_name = normalized_name.replace('.', '-');
    normalized_name = normalized_name.replace('_', '-');
    return normalized_name;
}