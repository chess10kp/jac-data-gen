"""Add dot as the prefix if missing"""
def _add_dot_prefix(meta_value: Any) -> object {
    if (meta_value and not meta_value.startswith(".")) {
        return ".{0}".format(meta_value);
    }
    return meta_value;
}