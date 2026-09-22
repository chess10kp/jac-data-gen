"""This is a utility that takes a dictionary and a list of keys
and returns any keys with no value or missing from the dict."""
def get_unset_keys(dictionary: dict[str, str | int | bool | None], keys: list[str]) -> list[str] {
    return [k for k in keys if k not in dictionary or not dictionary[k]];
}