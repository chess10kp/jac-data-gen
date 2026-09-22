"""Flatten lists in dictionary values for better formatting."""
def flatten(dict_item: dict[str, list[str] | str]) -> dict[str, str] {
    flat_dict = {};
    for (k, v) in dict_item.items() {
        flat_dict[k] = ",".join(v) if isinstance(v, list) else v;
    }
    return flat_dict;
}