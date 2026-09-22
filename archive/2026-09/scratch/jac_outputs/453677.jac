"""Transform stream name string to dictionary."""
def stream_name_to_dict(stream_name: str, separator: str = '-') -> dict[str, str | None] {
    catalog_name = None;
    schema_name = None;
    table_name = stream_name;
    s_parts = stream_name.split(separator);
    if len(s_parts) == 2 {
        schema_name = s_parts[0];
        table_name = s_parts[1];
    }
    if len(s_parts) > 2 {
        catalog_name = s_parts[0];
        schema_name = s_parts[1];
        table_name = '_'.join(s_parts[2:]);
    }
    return {
        'catalog_name': catalog_name,
        'schema_name': schema_name,
        'table_name': table_name
    };
}