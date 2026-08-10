"""Return bool param value."""
def get_bool_param(param: bool | str) -> bool {
    if isinstance(param, bool) {
        return param;
    }
    return True if param.strip().lower() == 'true' else False;
}