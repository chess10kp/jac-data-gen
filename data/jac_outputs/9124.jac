"""
    Collect not null key value pair from keyword arguments.

    .. versionadded:: 1.0.1
    """
def collect_not_null_kwargs(**kwargs: object) -> dict[str, object] {
    return {
        k: v
        for (k, v) in kwargs.items()
        if v is not None
    };
}