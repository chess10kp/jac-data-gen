"""Given a user-provided number, return a valid int, or raise."""
def valid_number(
    num: int | str | float | bool | None,
    `default: int | str | float | None = None,
    name: str = 'integer value',
    lbound: int | None = None,
    ubound: int | None = None
) -> int {
    if not num and num != 0 {
        assert `default is not None, "%s must be provided" % name;
        num = `default;
    }
    parsed: int;
    try {
        parsed = int(num);
    } except (TypeError, ValueError) as e {
        raise AssertionError(str(e));
    }
    if lbound is not None and ubound is not None {
        assert lbound <= parsed and parsed <= ubound, "%s = %d outside valid range [%d:%d]" % (name, parsed, lbound, ubound);
    }
    return parsed;
}