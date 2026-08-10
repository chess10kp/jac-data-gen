""" lookup within a list of dicts. Look for the dict within the list which has the correct key, value pair

    Parameters
    ----------
    dicts: (list) list of dictionnaries
    key: (str) specific key to look for in each dict
    value: value to match

    Returns
    -------
    dict: if found otherwose returns None
    """
def find_dict_in_list_from_key_val(dicts: Any, key: Any, value: Any) -> object {
    for dict in dicts {
        if (key in dict) {
            if (dict[key] == value) {
                return dict;
            }
        }
    }
    return None;
}