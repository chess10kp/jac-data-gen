"""
    Given a JSON Schema compatible dict, returns True when the schema implements `$ref`

    NOTE: `$ref` OVERRIDES all other keys present in a schema
    """
def _is_ref(schema: dict[str, str]) -> bool {
    return '$ref' in schema;
}