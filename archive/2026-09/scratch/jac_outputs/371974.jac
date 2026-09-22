"""Test whether there all of a particular combination of tags are in ``tags_dict``."""
def _identify_tag_combination(
    tags_dict: dict[str, str],
    test_tags_dict: dict[str, str],
    true_value: bool = True,
    none_value: None = None,
    **unused: object
) -> bool | None {
    return true_value if all(
        (key in tags_dict) and (value == tags_dict[key])
        for (key, value) in test_tags_dict.items()
    ) else none_value;
}