"""Initialise a nested dictionary with two levels."""
def init_nested_dict_zero(first_level_keys: list[str], second_level_keys: list[str]) -> dict[str, dict[str, int]] {
    return {
        first_level_key: {second_level_key: 0 for second_level_key in second_level_keys}
        for first_level_key in first_level_keys
    };
}