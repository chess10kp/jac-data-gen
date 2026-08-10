type SchemaValue = str | int | float | list[str | int | float];

"""
    Merges two JSON schemas on a column.
    """
def merge_schemas(
    schema: dict[str, SchemaValue],
    old_schema: dict[str, SchemaValue] | None
) -> dict[str, SchemaValue] | None {
    if old_schema is None {
        return schema;
    } elif schema['type'] != old_schema['type'] {
        return old_schema;
    } elif 'enum' in schema and 'enum' in old_schema {
        merged_enum = list(old_schema['enum']);
        for enum_val in schema['enum'] {
            if enum_val not in merged_enum {
                merged_enum.append(enum_val);
            }
        }
        return dict(old_schema, enum=merged_enum);
    } elif 'inclusiveMinimum' in schema and 'inclusiveMinimum' in old_schema {
        merged_min = min(schema['inclusiveMinimum'], old_schema['inclusiveMinimum']);
        merged_max = min(schema['inclusiveMaximum'], old_schema['inclusiveMaximum']);
        return dict(
            old_schema, inclusiveMinimum=merged_min, inclusiveMaximum=merged_max
        );
    }
}