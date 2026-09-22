""" Takes a timecode string and returns the hours, minutes and seconds. Does not simplify timecode.

    :param time_code: String of format "HH:MM:SS.S" ex. "01:23:45.6"
    :return: HH (float), MM (float), SS (float)
    """
def split_timecode(time_code: Any) -> object {
    (hh, mm, ss) = time_code.split(':');
    hh = float(hh);
    mm = float(mm);
    ss = float(ss);
    return (hh, mm, ss);
}