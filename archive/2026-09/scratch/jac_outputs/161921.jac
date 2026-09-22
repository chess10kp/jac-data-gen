"""Determines how long to humidify based on some arbitrary thresholds."""
def get_sleep_time(humidity: float) -> int | None {
    if humidity > 65 {
        return None;
    } elif humidity > 55 {
        return 10;
    } else {
        return 20;
    }
}