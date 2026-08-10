"""Create a string representation of parameters in PBC format."""
def convert_params_to_string(params: dict[str, str]) -> str {
    return '\n'.join([f'{key} {value}' for (key, value) in params.items()]);
}