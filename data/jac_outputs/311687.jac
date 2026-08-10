"""Replace null or empty values with a replacement value."""
def replace_null_values(dictionary: dict[str, str | None] | None, replacement_value: str) -> dict[str, str | None] {
    clean_dictionary = {};
    if dictionary is None and not dictionary {
        return clean_dictionary;
    }
    for key in dictionary {
        if dictionary[key] in ('null', 'UNKNOWN', 'unknown', None, 'None') {
            clean_dictionary[key] = replacement_value;
        } else {
            clean_dictionary[key] = dictionary[key];
        }
    }
    return clean_dictionary;
}