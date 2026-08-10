"""Flatten contact details to {key: {label, value}} entries."""
def transform_contact_details(data: dict[str, dict[str, object]]) -> dict[str, dict[str, object]] {
    transformed_data = {};
    for (key, value) in data.items() {
        if 'label' in value {
            transformed_data[key] = value;
        } else {
            for (key2, value2) in value.items() {
                transformed_data[('%s_%s' % (key, key2))] = {
                    'label': key2,
                    'value': value2
                };
            }
        }
    }
    return transformed_data;
}