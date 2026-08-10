"""

    :param selected_set:
    :param reference: list/dict, is full set list or a item2id dict
    :return:
    """
def create_one_hot_v(selected_set: Any, reference: Any) -> object {
    v = [0 for i in range(len(reference))];
    if (`type(reference) == `list) {
        for x in selected_set {
            v[reference.index(x)] = 1;
        }
    } elif (`type(reference) == `dict) {
        for x in selected_set {
            v[reference[x]] = 1;
        }
    } else {
        raise TypeError;
    }
    return v;
}