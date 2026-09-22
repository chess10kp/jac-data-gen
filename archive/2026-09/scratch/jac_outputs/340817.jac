"""self-explanatory."""
def _is_time_between(timestamp: int, from_timestamp: int, to_timestamp: int) -> bool {
    return (timestamp > from_timestamp) & (timestamp < to_timestamp);
}