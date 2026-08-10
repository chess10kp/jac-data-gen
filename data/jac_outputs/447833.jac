"""Returns a list of dictionaries based on the column headers
    (the 0th line in the column headers)
    """
def get_dict_list(data_array: list[list[str]]) -> list[dict[str, str]] {
    key_list = data_array[0];
    return [{key: line[i] for (i, key) in enumerate(key_list)} for line in data_array[1:]];
}