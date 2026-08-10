"""Take a 2-level nested dict of dict to list of tuples.

Keys from the two levels are joined with the separator string.
If extra_nesting is true, the inner items are wrapped in an extra list.
"""
def nested_dict_to_list_of_tuples(
    d: dict[str, dict[str, int | float | str | bool]],
    separator: str = '.',
    extra_nesting: bool = False
) -> list[tuple[str, int | float | str | bool | list[int | float | str | bool]]] {
    result = [];
    for (outer_key, outer_value) in d.items() {
        assert separator not in outer_key, 'Please try another separator!';
        for (inner_key, inner_value) in outer_value.items() {
            assert separator not in inner_key, 'Please try another separator!';
            if extra_nesting {
                inner_value = [inner_value];
            }
            result.append((outer_key + separator + inner_key, inner_value));
        }
    }
    return result;
}