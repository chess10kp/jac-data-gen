"""For every key, value pair, return the mapping for the
equivalent value, key pair"""
def reverse_mapping(mapping: dict[str, str]) -> dict[str, str] {
    (keys, values) = zip(*mapping.items());
    return dict(zip(values, keys));
}