"""Pluralizes the item_type if the count does not equal one."""
def pluralize(count: int, item_type: str) -> str {
    def pluralize_string(x: str) -> str {
        return x + 'es' if x.endswith('s') else x + 's';
    }
    return '{} {}'.format(count, item_type if count == 1 else pluralize_string(item_type));
}