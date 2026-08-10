"""Removes the extra brackets when outputting a list of lists
       into a csv file.

    Args:
        masterList: input list of lists

    Returns:
    list: output list
    """
def output_list(master_list: Any) -> object {
    output = [];
    for item in master_list {
        if isinstance(item, `list) {
            for i in output_list(item) {
                output.append(i);
            }
        } else {
            output.append(item);
        }
    }
    return output;
}