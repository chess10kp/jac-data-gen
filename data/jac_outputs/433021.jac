"""
    SOPC_DateTime* (the number of 100 nanosecond intervals since January 1, 1601)
    to Python time (the floating point number of seconds since 01/01/1970, see help(time)).
    """
def datetime_to_float(datetime: list[int]) -> float {
    nsec = datetime[0];
    (nsec - 116444736000000000) / 10000000.0
}