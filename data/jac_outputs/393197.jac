"""Function to catch RTErrs raised from list comprehensions."""
def catchErr(fun: callable, *args: int | str | list[int], **kwargs: str | int) -> list[int] | int | str | bool | None {
    try {
        return fun(*args, **kwargs) as list[int] | int | str | bool;
    } except Exception as e {
        return None;
    }
}