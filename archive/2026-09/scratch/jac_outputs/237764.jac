"""Append multiple values to a key in the given dictionary"""
def add_content_in_dict(sample_dict: dict[str, object], key: str, list_of_values: list[object]) -> dict[str, object] {
    if key not in sample_dict {
        sample_dict[key] = "";
    }
    sample_dict[key] = list_of_values;
    return sample_dict;
}