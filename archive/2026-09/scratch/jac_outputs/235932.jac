glob SECONDS_PER_DAY = 86400;

"""timestamp to day-timestamp

    Args:
        the_timestamp (int): the timestamp in sec

    Returns:
        int: day-timestamp
    """
def timestamp_to_day_timestamp(the_timestamp: int) -> int {
    the_block = the_timestamp // SECONDS_PER_DAY;
    return the_block * SECONDS_PER_DAY;
}