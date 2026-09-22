"""Extract default values from a json-schema describing configuration options."""
def _extract_default_values(config_schema: dict) -> dict | None {
    defaults = {};
    if 'properties' not in config_schema {
        return None;
    }
    for (key, value) in config_schema['properties'].items() {
        if isinstance(value, dict) and 'default' in value {
            defaults[key] = value['default'];
        } elif isinstance(value, dict) and value.get('type', '') == 'object' {
            defaults[key] = _extract_default_values(value);
        }
    }
    return defaults;
}