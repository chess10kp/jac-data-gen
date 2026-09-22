"""Translates integer list to number word list.
If there is no translation available,
"no translation" instead of the number word is added to the list."""
def translate_with_get(num_list: list[int], transl_dict: dict[int, str]) -> list[str] {
    return [transl_dict.get(item, "no translation") for item in num_list];
}