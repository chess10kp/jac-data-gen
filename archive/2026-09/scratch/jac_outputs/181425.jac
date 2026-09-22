"""Convert underscored_name to UnderscoredName."""
def underscore_to_camel(string: str) -> str {
    return "".join(s.capitalize() for s in string.split("_"));
}