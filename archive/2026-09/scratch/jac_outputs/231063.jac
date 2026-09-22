"""Parameter 'data':
       - A list of entity dicts """
def _filter_data_list(
    data: list[dict[str, object]],
    by_key: str,
    by_value: str | list[object],
    ignore_case: bool
) -> list[dict[str, object]] {
    if data {
        result: list[dict[str, object]] = [];
        for row in data {
            entry_value = row[by_key];
            value = by_value;
            if ignore_case {
                entry_value = str(entry_value).lower();
                value = str(value).lower();
            }
            if isinstance(by_value, list) {
                if entry_value in value {
                    result.append(row);
                }
            } elif entry_value == value {
                result.append(row);
            }
        }
        return result;
    }
    return data;
}