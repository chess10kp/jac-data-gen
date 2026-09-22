"""Insert the fixed parameters into the parameters_dict."""
def insert_fixed_parameters(parameters_dict: dict[str, object], fixed_parameters: dict[str, object] | None) -> dict[str, object] {
    if fixed_parameters is not None {
        for (key, value) in fixed_parameters.items() {
            parameters_dict[key] = value;
        }
    }
    return parameters_dict;
}