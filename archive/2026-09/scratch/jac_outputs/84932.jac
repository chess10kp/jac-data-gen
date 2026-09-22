"""Change a certain value from a dictionary."""
def change_dict_value(
    dictionary: dict[str, str | bool | None],
    old_value: str | bool | None,
    new_value: str | bool | None
) -> dict[str, str | bool | None] {
    for (key, value) in dictionary.items() {
        if value == old_value {
            dictionary[key] = new_value;
        }
    }
    return dictionary;
}