"""Generate paths to examine from a variable-type template."""
def _expand_check_paths(
    template: str | list[str | list | dict] | dict[str, str | list | dict],
    lookup_key: str | None
) -> list[str] {
    check_paths = [];
    if isinstance(template, dict) {
        if lookup_key is None {
            check_paths += _expand_check_paths(list(template.values()), lookup_key);
        } else {
            check_paths += _expand_check_paths(template.get(lookup_key, []), lookup_key);
        }
    } elif isinstance(template, list) {
        for value in template {
            check_paths += _expand_check_paths(value, lookup_key);
        }
    } else {
        check_paths += [template];
    }
    return check_paths;
}