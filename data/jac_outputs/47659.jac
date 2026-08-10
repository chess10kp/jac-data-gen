"""Check if a string value should be evaluated as True or False."""
def str_to_bool(param: bool | str) -> bool {
    if isinstance(param, bool) {
        return param;
    }
    return param.lower() in ("true", "yes", "1");
}