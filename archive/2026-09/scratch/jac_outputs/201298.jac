"""
    Parses the description of a request/response field.
    """
def parse_description(description: Any) -> object {
    if (description is None) {
        return None;
    }
    return description.lstrip(' /*').lstrip(' /**').replace('\n', ' ');
}