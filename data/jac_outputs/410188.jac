"""Switch keys with key values (unique identifier)."""
def reformat_dict_f(dic: dict[str, object], mapping: dict[str, str]) -> dict[str, object] {
    return {k: dic[v] for (k, v) in mapping.items()};
}