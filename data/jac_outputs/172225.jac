"""Create a concatenated sandbox dataset table name from namer and base name."""
def get_sandbox_table_name(table_namer: str, base_name: str) -> str {
    if table_namer and not table_namer.isspace() {
        return f'{table_namer}_{base_name}';
    } else {
        return base_name;
    }
}