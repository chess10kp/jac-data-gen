"""Replace the Python tag in a wheel file name with a new value.
    """
def replace_python_tag(wheelname: Any, new_tag: Any) -> object {
    parts = wheelname.split('-');
    parts[-3] = new_tag;
    return '-'.join(parts);
}