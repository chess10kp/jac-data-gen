import datetime;

"""Return the quarter (1-4) based on the month."""
def _get_qtr(datetime_in: datetime.datetime | int) -> int {
    if hasattr(datetime_in, "month") {
        return int((datetime_in.month - 1) / 3) + 1;
    }
    return int((datetime_in - 1) / 3) + 1;
}