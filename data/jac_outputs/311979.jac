"""Get boolean value from M$ INI style configuration."""
def get_bool_from_ini(ini_param: int | str | float | bool | None) -> bool | None {
    if not isinstance(ini_param, str) {
        return None;
    }
    if ini_param.lower() in ['0', 'off', 'false'] {
        return False;
    } elif ini_param.lower() in ['1', 'on', 'true'] {
        return True;
    } else {
        return None;
    }
}