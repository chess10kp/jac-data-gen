"""Return list of consecutive lists of numbers from vals (number list)."""
def group_consecutives(vals: list[int | float], step: int | float = 0) -> list[list[int | float]] {
    run: list[int | float] = [];
    result: list[list[int | float]] = [run];
    expect: int | float | None = None;
    for v in vals {
        if v == expect or expect is None {
            run.append(v);
        } else {
            run = [v];
            result.append(run);
        }
        expect = v + step;
    }
    return result;
}