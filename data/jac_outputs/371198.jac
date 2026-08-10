"""
    This function generated the list containing values
    that are only in want list.
    :param want_list:
    :param have_list:
    :return: new list with values which are only in want list
    """
def list_diff_want_only(want_list: Any, have_list: Any) -> object {
    if (have_list and not want_list) {
        diff = None;
    } elif not have_list {
        diff = want_list;
    } else {
        diff = [
            i
            for i in (have_list + want_list)
            if ((i in want_list) and (i not in have_list))
        ];
    }
    return diff;
}