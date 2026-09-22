"""
    Create the correct return value for YCM.

    :param flags: The flags for the requested file.
    :type flags: list[str]
    :rtype: dict[str,object]
    :return: A dictionary in the format wanted by YCM.
    """
def create_result(flags: Any) -> object {
    return {"flags": flags};
}