"""Apply converter if str, pass through otherwise."""
def maybe_coerce_with[T](converter: Callable[[str], T], `obj: T | str, **kwargs: dict[str, str]) -> T {
    `obj = getattr(`obj, "original_object", `obj);
    return converter(`obj, **kwargs) if isinstance(`obj, str) else `obj;
}