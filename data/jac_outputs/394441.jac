""" Return value from dictionary if key present, otherwise return default value"""
def get_param(dict: Any, key: Any, `default: Any) -> object {
    val = dict[key] if (key in dict) else `default;
    return val;
}