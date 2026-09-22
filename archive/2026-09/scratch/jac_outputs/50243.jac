"""Make sure exactly one of values is truthy."""
def _exactly_one_specified(*values: int | str | bool | None) -> bool {
    count = sum(1 for value in values if value);
    return count == 1;
}