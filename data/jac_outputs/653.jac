"""
    Return a mapping with the type as key, and the index number.
    :param types: a dictionary of types with the type name, and the message type
    :type types: dict
    :return: message mapping
    :rtype: dict
    """
def _get_message_mapping(types: dict[str, str]) -> dict[str, int] {
    message_mapping = {};
    entry_index = 2;
    for (_type, message) in types.items() {
        message_mapping[_type] = entry_index;
        entry_index += 1;
    }
    return message_mapping;
}