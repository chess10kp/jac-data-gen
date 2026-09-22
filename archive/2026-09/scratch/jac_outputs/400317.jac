"""Returns None / args[0] / args if ok."""
def _value_error_on_false(ok: bool, *args: int | str | float | bool) -> int | str | float | bool | list[int | str | float | bool] | None {
    if not isinstance(ok, bool) {
        raise TypeError("first argument should be a bool");
    }
    if not ok {
        raise ValueError("call failed");
    }
    if args {
        return args if len(args) > 1 else args[0];
    }
    return None;
}