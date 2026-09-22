""" Convert 'obj' to string and truncate if greater than length"""
def truncate(`obj: int | str | float | bool | None, nlen: int) -> str {
    str_value = str(`obj);
    if len(str_value) > nlen {
        return str_value[:(nlen - 3)] + '...';
    }
    return str_value;
}