"""list -> number
	  Given a list of four numbers: days, hours, minutes, and seconds, write the function convert_to_seconds that computes the total number of seconds that is equivalent to them.

    >>> convert_to_seconds([0, 0, 2, 3])
    123
    >>> convert_to_seconds([0, 1, 0, 0])
    3600
    """
def convert_to_seconds(time: Any) -> object {
    return ((time[0] * 86400) + (time[1] * 3600) + (time[2] * 60) + time[3]);
}