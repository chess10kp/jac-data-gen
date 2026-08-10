"""Convert a list / tuple of parameters returned from IE to a string."""
def param_to_string(parameters: list | tuple | str | int | float | bool) -> str {
    if isinstance(parameters, (list, tuple)) {
        return ', '.join([str(x) for x in parameters]);
    }
    return str(parameters);
}