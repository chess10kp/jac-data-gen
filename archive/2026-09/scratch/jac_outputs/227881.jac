"""
    :param states: no. of states
    :param dictionary: input distribution
    :return: a list of values for each states
    """
def dict_to_list(states: Any, dictionary: Any) -> object {
    rows = [];
    for i in states {
        rows.append(list(dictionary[i].values()));
    }
    return rows.copy();
}