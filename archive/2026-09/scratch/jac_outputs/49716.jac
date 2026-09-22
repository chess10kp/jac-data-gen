"""Clean redundant name from the name list.

    Args:
        name_list: The name list.

    Returns:
        return_name_list: The cleaned name list.
    """
def clean_name_list(name_list: list) -> list {
    return_name_list = [];
    for name in name_list {
        return_name = [name[0], name[1]];
        if (return_name not in return_name_list) {
            return_name_list.append(return_name);
        }
    }
    return return_name_list;
}