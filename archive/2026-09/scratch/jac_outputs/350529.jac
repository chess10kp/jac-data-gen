"""Calculate elapsed time."""
def timeCount(cur_time: float, start_time: float) -> tuple[str, float] {
    abs_t = cur_time - start_time;
    temp = abs_t;
    (d_unit, h_unit, m_unit) = (24 * 3600, 3600, 60);
    days = int(temp // d_unit);
    temp -= days * d_unit;
    hours = int(temp // h_unit);
    temp -= hours * h_unit;
    mins = int(temp // m_unit);
    format_t = ":".join([str(days), str(hours), str(mins)]);
    return (format_t, abs_t);
}