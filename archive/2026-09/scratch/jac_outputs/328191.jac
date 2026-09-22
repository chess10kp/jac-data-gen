"""Extract a slice of s from start to stop, taking every step characters."""
def filter_slice(
    s: str,
    start: str | int | None = None,
    stop: str | int | None = None,
    step: str | int | None = None
) -> str {
    xstart = None;
    xstop = None;
    xstep = None;
    if start {
        try {
            xstart = int(start);
        } except ValueError as e {
            xstart = 0;
        }
    }
    if stop {
        try {
            xstop = int(stop);
        } except ValueError as e {
            xstop = -1;
        }
    }
    if step {
        try {
            xstep = int(step);
        } except ValueError as e {
            xstep = 1;
        }
    }
    return s[slice(xstart, xstop, xstep)];
}