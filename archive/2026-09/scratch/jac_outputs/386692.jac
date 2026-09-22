"""
Expects a dictionary where all keys are strings. Returns a list of tuples containing the key vaue pair where the
keys are merged with a dot in between.
"""
def flatten_dict(dct: dict[str, object], key_string: str = "") -> list[tuple[str, object]] {
    result = [];
    for key in dct {
        updated_key_string = key_string + key + ".";
        if isinstance(dct[key], dict) {
            result = result + flatten_dict(dct[key], updated_key_string);
        } else {
            result.append((updated_key_string[:-1], dct[key]));
        }
    }
    return result;
}