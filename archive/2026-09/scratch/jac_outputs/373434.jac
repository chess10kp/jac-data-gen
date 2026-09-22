"""Reverse a dictionary, swapping keys and values."""
def inverse_dict(my_dict: dict[str, str]) -> dict[str, str] {
    result_dict = {};
    for (key, value) in my_dict.items() {
        if value not in result_dict {
            result_dict[value] = '';
        }
        result_dict[value] = key;
    }
    return result_dict;
}