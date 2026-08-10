"""
Translate a dictionary of attributes to a nested set of parameters suitable for QuerySet filtering.
"""
def dict_to_filter_params(d: dict[str, str | int | float | bool | dict], prefix: str = '') -> dict[str, str | int | float | bool] {
    params: dict[str, str | int | float | bool] = {};
    for (key, val) in d.items() {
        k = prefix + key;
        if isinstance(val, dict) {
            params.update(dict_to_filter_params(val as dict[str, str | int | float | bool | dict], k + '__'));
        } else {
            params[k] = val;
        }
    }
    return params;
}