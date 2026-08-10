"""Parse semicolon-delimited key-value pairs into name/value dicts."""
def _parse_domain_specific_input(input_str: str) -> list[dict[str, str]] {
    def _get_comma_separated_params(key_value_pair_str: str) -> dict[str, str] {
        param_items = key_value_pair_str.split(",", 1);
        param_items = [s.strip() for s in param_items];
        return {"name": param_items[0], "value": ",".join(param_items[1:])};
    }
    params_list = input_str.split(";");
    return [
        _get_comma_separated_params(item)
        for item in params_list
        if item
    ];
}