"""Test if the function func is a lambda ("anonymous" function)."""
def islambda(func: Callable[..., str]) -> bool {
    return getattr(func, 'func_name', False) == '<lambda>';
}