"""Change the schema to inherit from _OpenAPIGenBaseModel."""
def inherit_fom_basemodel(model: dict[str, object]) -> dict[str, object] {
    base: dict[str, object] = {
        'allOf': [
            {'$ref': '#/components/schemas/_OpenAPIGenBaseModel'},
            {'type': 'object', 'properties': {}}
        ]
    };
    high_level_keys = {'title', 'description'};
    for (key, value) in model.items() {
        if key in high_level_keys { base[key] = model[key]; }
        else { base['allOf'][1][key] = value; }
    }
    return base;
}