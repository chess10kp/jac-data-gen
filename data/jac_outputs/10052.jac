"""String to bool conversion function for use with args.get(...)."""
def rb_is_true(value: str) -> bool {
    return value.lower() == "true";
}