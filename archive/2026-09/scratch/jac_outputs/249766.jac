"""
    If options is none or empty, return defaultOptions directly;
    Otherwise set option in options if option exist in defaultOptions but does not exist in options.
    """
def setDefaultOptionIfMissing(options: dict[str, str] | None, defaultOptions: dict[str, str]) -> dict[str, str] {
    if not defaultOptions {
        return {} if options is None else options;
    }
    if not options {
        return dict(defaultOptions);
    }
    for (key, value) in defaultOptions.items() {
        if key not in options {
            options[key] = value;
        }
    }
    return options;
}