"""
    Returns the last list size saved for the provided list
    :param list_id:
    :param all_lists_state:
    :return:
    """
def find_old_list_count(list_id: Any, all_lists_state: Any) -> object {
    last_size = 0;
    for x in all_lists_state {
        if (x['id'] == list_id) {
            last_size = x['member_count'];
        }
    }
    return last_size;
}