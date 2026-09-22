"""
Returns a new dictionaries whose keys have been passed through
`formatter`, which should be a function that formats strings.
"""
def format_dictionary_keys(dictionary: dict[str, bool | int | float | str], formatter: callable) -> dict[str, bool | int | float | str] {
    new: dict[str, bool | int | float | str] = {};
    for (key, value) in dictionary.items() {
        assert isinstance(key, str);
        new[formatter(key)] = value;
    }
    return new;
}