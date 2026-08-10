"""Return args, p, and kwargs alongside placeholder None values."""
def func_args_p_kwargs(*args: int, p: str = "p", **kwargs: int) -> tuple[None, None, None, None, list[int], str, None, dict[str, int]] {
    return (None, None, None, None, args, p, None, kwargs);
}