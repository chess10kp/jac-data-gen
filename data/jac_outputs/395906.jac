""" Take a dict of key->values and return values->[keys] """
def invert_dict(front_dict: dict[str, str]) -> dict[str, list[str]] {
    back_dict = {value: [] for value in front_dict.values()};
    for (key, value) in front_dict.items() {
        back_dict[value].append(key);
    }
    return back_dict;
}