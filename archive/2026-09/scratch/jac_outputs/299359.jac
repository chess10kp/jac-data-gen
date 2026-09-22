"""return the component name in capitalized format

    Args:
        context (dict): complete package and component transformation

    Returns:
        str: component name in capitalized format, underscore being removed.

    Examples:
        >>> context = {componentName="another_comp" frecuency="100"/>
        >>> capitalized_comp_name(context)
        "AnotherComp"
    """
def capitalized_comp_name(context: Any) -> object {
    return context['componentName'].title().replace("_", "");
}