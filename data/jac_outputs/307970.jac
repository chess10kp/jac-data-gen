"""Convert boolean representations of TRUE/FALSE to an integer value."""
def boolean_to_integer(boolean: bool) -> int {
    _result = 0;
    if boolean {
        _result = 1;
    }
    return _result;
}