"""To facilitate readability via newlines, we express some JSON
    strings as arrays, but store them as strings.

    Returns the json with such fields converted to strings.

    """
def arrays_to_strings(measure_json: Any) -> object {
    fields_to_convert = [
        'title',
        'description',
        'why_it_matters',
        'numerator_columns',
        'numerator_where',
        'denominator_columns',
        'denominator_where'
    ];
    for field in fields_to_convert {
        if isinstance(measure_json[field], `list) {
            measure_json[field] = ' '.join(measure_json[field]);
        }
    }
    return measure_json;
}