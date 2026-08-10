"""Look up a custom parameter value by key."""
def get_custom_params_value(custom_params_list: list[dict[str, str]], key: str) -> str | None {
    for param in custom_params_list {
        if param['name'] == key {
            return param['value'];
        }
    }
    return None;
}