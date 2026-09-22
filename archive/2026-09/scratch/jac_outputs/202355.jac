"""Run func until it returns a non-None value, then return that value."""
def restart_function(func: callable[[], object | None]) -> object {
    while True {
        returned_value = func();
        if returned_value is not None { break; }
    }
    return returned_value;
}