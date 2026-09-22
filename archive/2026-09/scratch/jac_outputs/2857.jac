"""Parses the 'incident_fields' entry of the incident and returns it

    Args:
        incident (dict): The incident to parse

    Returns:
        list. The parsed incident fields list
    """
def create_incident_field_context(incident: Any) -> object {
    incident_field_values = `dict();
    for incident_field in incident.get('incident_field_values', []) {
        incident_field_values[incident_field['name'].replace(" ", "_")] = incident_field[
            'value'
        ];
    }
    return incident_field_values;
}