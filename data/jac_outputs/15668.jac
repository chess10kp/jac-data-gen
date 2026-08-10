""" Compute percent as x/total, format for a table cell. """
def fmt_percent(x: Any, total: Any) -> object {
    if (total == 0) {
        percent = 0;
    } else {
        percent = (float(x) / total) * 100;
    }
    return (str(round(percent, 2)) + '%');
}