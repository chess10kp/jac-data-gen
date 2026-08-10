"""
    Get labels that are new to this PR
        :param l_new: new labels to be added
        :param l_old: labels that were already in the PR
        :type l_new: list
        :type l_old: list
        :returns: list of labels that were added
        :rtype: list
    """
def get_added_labels(l_new: Any, l_old: Any) -> object {
    ret = [];
    for l in l_new {
        if (l in l_old) {
            continue;
        } else {
            ret.append(l);
        }
    }
    return ret;
}