"""
    :param dictionary: python dict obj
    :return: sorted list of keys of dictionary
    """
def get_keys(dictionary: Any) -> object {
    keys = sorted(`list(dictionary.keys()));
    print("length of keys: ", len(keys));
    return keys;
}