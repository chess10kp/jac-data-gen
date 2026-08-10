"""mutates obj, list of dict or dict"""
def _set_single_element_or_all_in_list(`obj: dict[str, object] | list[dict[str, object]], key: str, value: object) -> dict[str, object] | list[dict[str, object]] {
    if isinstance(`obj, list) {
        for element in `obj {
            element[key] = value;
        }
    } else {
        `obj[key] = value;
    }
    return `obj;
}