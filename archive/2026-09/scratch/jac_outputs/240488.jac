"""Returns map from string to index in array. """
def get_str2id(strings_array: list[str]) -> dict[str, int] {
    str2id = {};
    for (i, s) in enumerate(strings_array) {
        str2id[s] = i;
    }
    return str2id;
}