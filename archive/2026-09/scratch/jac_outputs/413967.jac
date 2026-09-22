"""
    Given column_type string returns boolean value
    if given string is for MapType.
    :param column_type: string description of
        column type
    :return: boolean - MapType or not.
    """
def _is_map_type(column_type: str) -> bool {
    return column_type.find("map<") != -1;
}