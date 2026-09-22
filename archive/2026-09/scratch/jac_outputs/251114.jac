"""
    Utility method for formatting a dictionary of headers.

    Params:
        unformatted_dict (dict): Unformatted dictionary being submitted for formatting.

    Returns:
        formatted_headers (dict): Dictionary that has been camel cased with spaces replacing
        underscores("_")
    """
def format_headers(unformatted_dict: Any) -> object {
    formatted_headers = `list();
    for field in unformatted_dict['ModelBase'] {
        formatted_headers.append(field.replace('_', " ").title());
    }
    return formatted_headers;
}