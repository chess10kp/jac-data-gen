"""Converts a two-level dictionary to a single level dictionary
dict[meeting][speaker] --> dict[speaker]"""
def two_level_to_single_level_dict(two_level_dict: dict[str, dict[str, list[str] | str]]) -> dict[str, list[str]] {
    assert isinstance(next(iter(two_level_dict.values())), dict);
    single_level_dict: dict[str, list[str]] = {};
    for (_, inner_dict) in two_level_dict.items() {
        for (speaker, value) in inner_dict.items() {
            if speaker not in single_level_dict {
                single_level_dict[speaker] = [];
            }
            if isinstance(value, list) {
                single_level_dict[speaker].extend(value);
            } else {
                single_level_dict[speaker].append(value);
            }
        }
    }
    return single_level_dict;
}