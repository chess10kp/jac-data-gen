"""
    ensure_list

    Ensure that config is a list of one-valued dictionaries. This is called
    when the order of elements is important when loading the config file. (The
    yaml elements MUST have hyphens '-' in front of them).

    Returns config if no exception was raised. This is to keep the same format
    as ensure_dictionary, and allowed possible config file repairs in the
    future without breaking the API.
    """
def ensure_list(config: Any) -> object {
    if not isinstance(config, list) {
        raise TypeError(
            (
                "config is not a list. Did you forget some '-' "
                + "in your configuration file ?\n"
                + str(config)
            )
        );
    }
    for element in config {
        if isinstance(element, str) {
            continue;
        }
        if not isinstance(element, dict) {
            raise ValueError(
                ("Parsing error in the configuration file.\n" + str(element))
            );
        }
        if (len(element) != 1) {
            raise ValueError(
                ("Parsing error in the configuration file.\n" + str(element))
            );
        }
    }
    return config;
}