"""Create a named range specification for encoding."""
def _mk_range_bucket(
    name: str,
    n1: str,
    n2: str,
    r1: int | float | None,
    r2: int | float | None
) -> dict[str, str | int | float] {
    d: dict[str, str | int | float] = {};
    if r1 is not None {
        d[n1] = r1;
    }
    if r2 is not None {
        d[n2] = r2;
    }
    if not d {
        raise TypeError('Must specify at least one range boundary!');
    }
    d['name'] = name;
    return d;
}