""" A wrapper function to get a specification as a dictionary. """
def get_option_specs(
    name: str,
    required: bool = False,
    `default: int | float | str | None = None,
    help_str: str = '',
    **kwargs: str | int | float | bool | None
) -> dict[str, str | int | float | bool | type | None] {
    ret: dict[str, str | int | float | bool | type | None];
    if isinstance(`default, int) {
        ret = {
            'name': name,
            'required': required,
            'default': `default,
            'help': help_str,
            'type': int
        };
    } elif isinstance(`default, float) {
        ret = {
            'name': name,
            'required': required,
            'default': `default,
            'help': help_str,
            'type': float
        };
    } else {
        ret = {
            'name': name,
            'required': required,
            'default': `default,
            'help': help_str
        };
    }
    for (key, value) in list(kwargs.items()) {
        ret[key] = value;
    }
    return ret;
}