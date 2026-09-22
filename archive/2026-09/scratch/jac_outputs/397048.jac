""" Gets list of unique target names and return dictionary
    """
def get_unique_value_from_summary_ext(
    test_summary: list[dict[str, str]],
    index_key: str,
    index_val: str
) -> dict[str, str] {
    result = {};
    for `test in test_summary {
        key = `test[index_key];
        val = `test[index_val];
        if key not in result {
            result[key] = val;
        }
    }
    return result;
}