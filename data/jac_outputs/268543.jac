"""
    try to detect if a chandle stick fall in the pattern of a doji, long-shadow and hammer
    :daily_movement_minimum: default to 0.01 (1%)
    """
def long_tail_reversal(
    close: Any,
    open: Any,
    high: Any,
    low: Any,
    trend: Any = 'up',
    daily_movement_minimum: Any = 0.01
) -> object {
    detected = False;
    mid_point_magnatude_scaling = 0.8;
    if ((abs((high - low)) / open) < daily_movement_minimum) {
        return False;
    }
    if (trend == 'up') {
        mid_point = (((high - low) / 2.0) * mid_point_magnatude_scaling) + low;
        if ((open >= mid_point) and (close >= mid_point)) {
            detected = True;
        }
    } else {
        mid_point = (
            (((high - low) / 2.0) * (1 + (1 - mid_point_magnatude_scaling))) + low
        );
        if ((open <= mid_point) and (close <= mid_point)) {
            detected = True;
        }
    }
    return detected;
}