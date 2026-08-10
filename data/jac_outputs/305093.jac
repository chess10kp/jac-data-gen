"""
    Rounds up time to the higher multiple of period
    For example, if period=5, then time=16s will be rounded to 20s
    if time=15, then time will remain 15
    """
def _round_up_time(time: int | float, period: int | float) -> int | float {
    if time % period == 0 {
        return time;
    }
    time = round(time);
    return time + period - (time % period);
}