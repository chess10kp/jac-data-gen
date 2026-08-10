"""Counts number of satellites used in calculation from total visible satellites
    Arguments:
        feed feed=data_stream.satellites
    Returns:
        total_satellites(int):
        used_satellites (int):
    """
def satellites_used(feed: list[dict[str, bool]]) -> tuple[int, int] {
    total_satellites = 0;
    used_satellites = 0;
    if not isinstance(feed, list) {
        return (0, 0);
    }
    for satellites in feed {
        total_satellites += 1;
        if satellites['used'] is True {
            used_satellites += 1;
        }
    }
    return (total_satellites, used_satellites);
}