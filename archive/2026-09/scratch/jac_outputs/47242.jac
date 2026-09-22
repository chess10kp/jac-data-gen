"""given an arg string list, parse out into a dict
assumes a format of: key=indices

NOTE: this is for smart indexing into tensor dicts (mostly label sets)

Returns:
  list of tuples, where tuple is (dataset_key, indices_list)"""
def _parse_to_key_and_indices(key_strings: list[str]) -> list[tuple[str, list[int]]] {
    ordered_keys = [];
    for key_string in key_strings {
        key_and_indices = key_string.split("=");
        key = key_and_indices[0];
        if len(key_and_indices) > 1 {
            indices = [int(i) for i in key_and_indices[1].split(",")];
        } else {
            indices = [];
        }
        ordered_keys.append((key, indices));
    }
    return ordered_keys;
}