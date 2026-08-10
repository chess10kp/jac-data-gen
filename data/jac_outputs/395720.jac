"""
    min-max normalization for dictionary
    :param dict1: input dictionary
    :return: min-max normalized dictionary
    """
def norm_min_max_dict(dict1: Any) -> object {
    for (key, value) in dict1.items() {
        dict1[key] = round(
            (
                (dict1[key] - min(dict1.values()))
                / (max(dict1.values()) - min(dict1.values()))
            ),
            3
        );
    }
    return dict1;
}