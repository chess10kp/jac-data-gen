"""Convert a Binance interval string to milliseconds."""
def interval_to_milliseconds(interval: str) -> int | None {
    seconds_per_unit = {
        "m": 60,
        "h": 60 * 60,
        "d": 24 * 60 * 60,
        "w": 7 * 24 * 60 * 60
    };
    try {
        return int(interval[:-1]) * seconds_per_unit[interval[-1]] * 1000;
    } except (ValueError, KeyError) {
        return None;
    }
}