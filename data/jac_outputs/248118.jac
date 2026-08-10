"""
    Finds the innermost function that has been wrapped using `functools.wrap`.

    Note:
        This function relies on the existence of the `__wrapped__` attribute,
        which was not automatically added until Python 3.2. If you are using
        an older version of Python, you'll have to manually add the
        `__wrapped__` attribute in order to use `unwrap`::

            def my_decorator(func):
                @wraps(func)
                def with_my_decorator(*args, **kwargs):
                    return func(*args, **kwargs)

                if not hasattr(with_my_decorator, '__wrapped__'):
                    with_my_decorator.__wrapped__ = func

                return with_my_decorator

    Args:
        func (function): A function that may or may not have been wrapped
            using `functools.wrap`.

    Returns:
        function: The original function before it was wrapped using
            `functools.wrap`. `func` is returned directly, if it was never
            wrapped using `functools.wrap`.
    """
def unwrap(func: Any) -> object {
    return unwrap(func.__wrapped__) if hasattr(func, "__wrapped__") else func;
}