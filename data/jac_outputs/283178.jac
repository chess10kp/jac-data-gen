"""Ensure that the dict has all of the information available. If not, return what does"""
def filter_query(filter_dict: dict[str, object], required_keys: list[str]) -> list[str] {
    if not isinstance(filter_dict, dict) {
        raise TypeError("dict_list is not a list. Please try again");
    }
    if not isinstance(required_keys, list) {
        raise TypeError("dict_list is not a list. Please try again");
    }
    return [k for k in filter_dict if k in required_keys];
}