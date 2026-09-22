"""Edit defaulted argument dictionary and return it."""
def edit_args_dict(key: str, new_value: str | bool | None) -> dict[str, str | bool | None] {
    defaulted_args_dict: dict[str, str | bool | None] = {
        'begin': None,
        'finish': False,
        'current': False,
        'summary': None,
        'list': False,
        'tag': None,
        'edit': None,
        'remove': None
    };
    defaulted_args_dict[key] = new_value;
    return defaulted_args_dict;
}