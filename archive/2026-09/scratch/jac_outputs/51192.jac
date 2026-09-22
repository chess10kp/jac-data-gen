"""
    Interprets the argument as a time of day specification.  The 'time_spec'
    can be a number between zero and 24 or a string containing am, pm, and
    colons (such as "3pm" or "21:30").  If the interpretation fails, an
    exception is raised.  Returns the number of seconds since midnight.
    """
def seconds_since_midnight(time_spec: int | float | str) -> int {
    orig = time_spec;
    try {
        if type(time_spec) == type('') {
            ts = time_spec as str;
            assert '-' not in ts;
            ampm: str | None = None;
            ts = ts.strip();
            if ts[-2:].lower() == 'am' {
                ampm = "am";
                ts = ts[:-2];
            } elif ts[-2:].lower() == 'pm' {
                ampm = "pm";
                ts = ts[:-2];
            } elif ts[-1:].lower() == 'a' {
                ampm = "am";
                ts = ts[:-1];
            } elif ts[-1:].lower() == 'p' {
                ampm = "pm";
                ts = ts[:-1];
            }
            L = [s.strip() for s in ts.split(':')];
            assert len(L) == 1 or len(L) == 2 or len(L) == 3;
            L2 = [int(i) for i in L];
            hr = L2[0];
            mn = 0;
            sc = 0;
            if ampm {
                if ampm == 'am' {
                    if hr == 12 {
                        hr = 0;
                    } else {
                        assert hr < 12;
                    }
                } elif hr == 12 {
                    hr = 12;
                } else {
                    assert hr < 12;
                    hr += 12;
                }
            } else {
                assert hr < 24;
            }
            if len(L2) > 1 {
                mn = L2[1];
                assert mn < 60;
            }
            if len(L2) > 2 {
                sc = L2[2];
                assert sc < 60;
            }
            nsecs = hr * 60 * 60 + mn * 60 + sc;
        } else {
            assert not (time_spec < 0) and time_spec < 24;
            nsecs = int(time_spec) * 60 * 60;
        }
    } except Exception {
        raise Exception("invalid time-of-day specification: " + str(orig));
    }
    return nsecs;
}