"""A recursive version of Python dict#update"""
def recursive_update(`default: Any, custom: Any) -> object {
    if (not isinstance(`default, dict) or not isinstance(custom, dict)) {
        raise TypeError('Params of recursive_update() must be a dictionnaries.');
    }
    for key in custom {
        if (isinstance(custom[key], dict) and isinstance(`default.get(key), dict)) {
            `default[key] = recursive_update(`default[key], custom[key]);
        } else {
            `default[key] = custom[key];
        }
    }
    return `default;
}