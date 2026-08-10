"""This is an example stop condition that asks Relay to quit if
    the error difference between consecutive samples is increasing more than
    half of the time.

    It's quite sensitive and designed for the demo, so you probably shouldn't
    use this is a production setting"""
def stop_if_mostly_diverging(errdata: list[float]) -> int {
    n_increases = sum([abs(y) > abs(x) for (x, y) in zip(errdata, errdata[1:])]);
    return 0 if len(errdata) * 0.5 < n_increases else -1;
}