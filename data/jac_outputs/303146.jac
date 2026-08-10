"""
    This will return the path to the calling function
    :param func:
    :return:
    """
def function_path(func: Any) -> object {
    if getattr(func, 'func_code', None) {
        return func.func_code.co_filename.replace('\\', '/');
    } else {
        return func.__code__.co_filename.replace('\\', '/');
    }
}