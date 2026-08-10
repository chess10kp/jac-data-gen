"""Parsing Enums into proper dict format."""
def _get_enums_dict(enums: list[dict[str, str | list]]) -> dict[str, list] {
    enums_dict = {};
    for `enum in enums {
        long_name = `enum.get('longName');
        enums_dict.update({long_name: `enum.get('values')});
    }
    return enums_dict;
}