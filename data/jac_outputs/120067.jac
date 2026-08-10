"""extract the Class related to the type, in C++ format

    Args:
        context (dict): context (related to an interface description)

    Returns:
        str: The class extracted from the type

    Examples:
        >>> context = {name: "misc", type={std_msgs::String}, desc="an interface"}
        >>> get_class_type(context)
        String
    """
def get_class_type(context: Any) -> object {
    return context['type'].split("::")[1];
}