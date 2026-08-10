"""Iterates through all key/value pairs in the property dictionary. If the "test_key" function returns True for a particular property key, then makes that property optional. Returns the updated property dict."""
def _MakeOptional(
    property_dict: dict[str, dict[str, bool]], test_key: Callable[[str], bool]
) -> dict[str, dict[str, bool]] {
    for (key, value) in property_dict.items() {
        if test_key(key) {
            property_dict[key]['required'] = False;
        }
    }
    return property_dict;
}