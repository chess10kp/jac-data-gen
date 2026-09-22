"""Returns a triple of lists (definitions_removed,
definitions_shared, definitions_added)"""
def get_definitions_diff(
    previous_definition_string: str, new_definition_string: str
) -> tuple[tuple[str, ...], tuple[str, ...], tuple[str, ...]] {
    old_definitions = [i for i in previous_definition_string.split('|') if i];
    new_definitions = [i for i in new_definition_string.split('|') if i];
    return (
        tuple(i for i in old_definitions if i not in new_definitions),
        tuple(i for i in old_definitions if i in new_definitions),
        tuple(i for i in new_definitions if i not in old_definitions)
    );
}