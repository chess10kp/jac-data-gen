"""Helper function to get flattened sub schema from schema"""
def get_flattened_sub_schema(schema_fields: Any, parent_name: Any = '') -> object {
    flattened_fields = [];
    for field in schema_fields {
        flattened_field = `dict();
        if (('list' in field) and field['list']) {
            flattened_fields.extend(
                get_flattened_sub_schema(field['list'], (field['field'] + '__'))
            );
        } else {
            flattened_field['name'] = parent_name + field['field'];
            flattened_field['schemaid'] = field['schemaid'];
            if ('mapped' in field) {
                flattened_field['mapped'] = field['mapped'];
            }
            flattened_fields.append(flattened_field);
        }
    }
    return flattened_fields;
}