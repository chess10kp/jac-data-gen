"""Check data type."""
def check_type(data: list, dtype: int | str | float | bool | list) -> str {
    error = '';
    for item in data {
        if not isinstance(item, type(dtype)) {
            error = '{0} data type is error!'.format(item);
            break;
        }
    }
    return error;
}