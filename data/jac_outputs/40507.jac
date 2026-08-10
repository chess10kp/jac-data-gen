"""
Function to (recursively) sort dictionaries used for package data. This procedure is used to ensure
that models always produce the same hash independent of the order of the keys in the dictionaries.
Sorting is done by the Python internal sorting methods depending on the data. This means sorting only
works for keys with same type and otherwise will throw a TypeError.
"""
def sort_dictionary(dictionary: dict, recursive: bool) -> dict {
    if not isinstance(dictionary, dict) {
        raise TypeError("input is not of type dict");
    }
    if not isinstance(recursive, bool) {
        raise TypeError("recursive is not of type bool");
    }
    if recursive {
        for (key, value) in dictionary.items() {
            if isinstance(value, dict) {
                dictionary[key] = sort_dictionary(value, recursive);
            }
        }
    }
    return dict(sorted(dictionary.items(), key=lambda (kv: tuple) { (kv[0], kv[1]); }));
}