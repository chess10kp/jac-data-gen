"""Replace `None` value in the `result_dict` to a string '-'."""
def parse_none_results(result_dict: dict[str, list[str | None]]) -> dict[str, list[str | None]] {
    for (key, value_list) in result_dict.items() {
        for (i, value) in enumerate(value_list) {
            if value is None {
                result_dict[key][i] = '-';
            }
        }
    }
    return result_dict;
}