"""
    Filter out the labels that match the configuration file
        :param labels_curr: known labels
        :param pattern_dict: dirtionary containing all the mach rules
        :type labels_curr: list
        :type pattern_dict: dictionary
        :returns: list of labels
        :rtype: list
    """
def get_unknown_labels_to_keep(labels_curr: Any, pattern_dict: Any) -> object {
    ret = [];
    pat = [];
    for `entry in pattern_dict {
        pat.append(`entry);
    }
    for l in labels_curr {
        if (l in pat) {
            continue;
        } else {
            ret.append(l);
        }
    }
    return ret;
}