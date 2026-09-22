"""Returns the key that maps to the maximal value in the given dict."""
def get_key_of_max[K, V](dict_obj: dict[K, V]) -> K {
    return max(dict_obj, key=lambda (key: K) { dict_obj[key]; });
}