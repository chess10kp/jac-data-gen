"""
    csv and json format output contain this non human readable header string:
    no CamelCase and no space.
    """
def __uglify(text: str) -> str {
    return text.lower().replace(' ', '_');
}