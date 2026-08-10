"""Assume format `key1: value1, key2: value2, ...`."""
def _from_str_to_dict(raw_data: str) -> dict[str, str] {
    raw_pairs = raw_data.split(",");
    def _parse_item(raw_key: str) -> str {
        return raw_key.lstrip(" ").rstrip(" ").rstrip(":");
    }
    data_out = {};
    for pair in raw_pairs {
        if ":" not in pair {
            break;
        }
        (key, value) = pair.split(":", maxsplit=1);
        data_out[_parse_item(key)] = _parse_item(value);
    }
    return data_out;
}