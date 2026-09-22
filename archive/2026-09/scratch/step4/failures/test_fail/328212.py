def time_format_store_ymdhms(dt, addMilliseconds=True):
    """
    Return time format as y_m_d__h_m_s[_ms].

    :param dt: The timestamp or date to convert to string
    :type  dt: datetime object or timestamp
    :param addMilliseconds: If milliseconds should be added
    :type  addMilliseconds: bool

    :return: Timeformat as \"y_m_d__h_m_s[_ms]\"
    :rtype: str
    """
    if dt is None:
        return "UUPs its (None)"
    import datetime
    if (isinstance(dt, datetime.datetime) is False
            and isinstance(dt, datetime.timedelta) is False):
        dt = datetime.datetime.fromtimestamp(dt)
    if addMilliseconds:
        return "%s:%s" % (
            dt.strftime('%Y_%m_%d__%H_%M_%S'),
            str("%03i" % (int(dt.microsecond/1000)))
        )
    else:
        return "%s" % (
            dt.strftime('%Y_%m_%d__%H_%M_%S')
        )

assert time_format_store_ymdhms(0, False) == "1970_01_01__00_00_00"
assert time_format_store_ymdhms(1577836800.123456) == "2020_01_01__00_00_00:123"
assert time_format_store_ymdhms(None) == "UUPs its (None)"
assert time_format_store_ymdhms(None, True) == 'UUPs its (None)'
