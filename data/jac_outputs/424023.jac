"""Returns true if result_data indicates a failure."""
def IsResultFailure(result_data: list | int | str) -> bool {
    while isinstance(result_data, list) {
        result_data = result_data[0];
    }
    if not result_data {
        return False;
    }
    return result_data not in (0, 1, '0', '1');
}