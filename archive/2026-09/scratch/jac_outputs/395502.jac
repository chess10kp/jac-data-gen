"""AND filter returns documents that contain fields matching all of the values.

    Returns a list of "term" filters: one for each of the filter values.

    """
def and_field_filters(field_name: Any, field_values: Any) -> object {
    return [{"term": {field_name: value}} for value in field_values];
}