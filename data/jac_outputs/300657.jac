"""Formats the duration (milliseconds) to a human readable way.

    :param duration: Duration in milliseconds
    :return: Duration in HOURS:MINUTES:SECONDS format. Example: 01:05:10
    """
def format_duration(duration: float) -> object {
    (m, s) = divmod((duration / 1000), 60);
    (h, m) = divmod(m, 60);
    if h {
        return "{0}:{1:0>2}:{2:0>2}".format(
            str(int(h)).zfill(2), str(int(m)).zfill(2), str(int(s)).zfill(2)
        );
    } else {
        return "{0}:{1:0>2}".format(str(int(m)).zfill(2), str(int(s)).zfill(2));
    }
}