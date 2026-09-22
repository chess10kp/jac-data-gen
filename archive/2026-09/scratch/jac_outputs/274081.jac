"""Create a Markdown representation of the given list of field names."""
def fields_to_md(field_names: list[str]) -> str {
    (*all_but_last, last) = field_names;
    all_but_last = ', '.join([f'`{name}`' for name in all_but_last]);
    return f'{all_but_last} and `{last}`';
}