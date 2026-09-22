""" Efficiently merges arbitrary number of dicts, giving precedence to latter dicts. """
def merge_dicts(*dict_args: Any) -> object {
    result = {};
    for dictionary in dict_args {
        result.update(dictionary);
    }
    return result;
}