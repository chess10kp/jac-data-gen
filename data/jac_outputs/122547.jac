""" Finds the key and associated value from the lookup value based on the location of the lookup value """
def get_key_and_value(`dict: Any, lookup_value: Any, value_loc: Any) -> object {
    for (key, value) in `dict.items() {
        if (lookup_value == value[value_loc[0]][value_loc[1]]) {
            return (key, value);
        }
    }
    return (None, None);
}