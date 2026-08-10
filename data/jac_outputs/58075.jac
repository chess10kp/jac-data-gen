"""
    Format the name of config parameter, adding the target language of necessary.

    :param config_parameter: Name of config parameter.
    :type config_parameter: str
    :param language: Pipeline language.
    :type language: str
    :return: Formatted config parameter.
    :rtype: str
    """
def format_config_parameter(config_parameter: Any, language: Any) -> object {
    if ("{language}" in config_parameter) {
        return config_parameter.format(language=language.upper());
    }
    return config_parameter;
}