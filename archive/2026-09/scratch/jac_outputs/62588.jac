"""Return true if func(value) returns is true or if *func* is *value*."""
def _check_callable(func: object, value: object) -> bool | object {
    return value is func or func(value);
}