"""Always returns integer value from string/None argument. Returns 0 if argument is None.
    """
def safe_int(str_value: str | None, base: int = 10) -> int {
    if str_value {
        return int(str_value, base);
    }
    return 0;
}