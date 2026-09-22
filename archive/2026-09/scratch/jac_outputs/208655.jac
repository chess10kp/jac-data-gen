"""Remove `excess_keys` from `dictionary`"""
def remove_keys_from_dict(dictionary: dict[str, object], excess_keys: Iterable[str]) -> dict[str, object] {
    dictionary = dictionary.copy();
    for key in excess_keys {
        dictionary.pop(key, None);
    }
    return dictionary;
}