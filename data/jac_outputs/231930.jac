"""
    A way to generate varying timeouts based on ranges
  """
def get_timeout(
    gross_time: int,
    start: int,
    end: int,
    precision: int | float,
    split_range: bool
) -> float {
    if split_range {
        top_num = float(end) / precision;
        bottom_num = float(start) / precision;
        if gross_time % 2 == 0 {
            timeout = top_num - float(gross_time) / precision;
        } else {
            timeout = bottom_num + float(gross_time) / precision;
        }
    } else {
        timeout = float(gross_time) / precision;
    }
    return timeout;
}