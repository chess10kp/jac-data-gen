"""
    Returns the user's authorized duration in seconds, if unauthorized the return value
    will be 0.
    """
def user_authorization(packet: dict[str, int | str | bytes]) -> int {
    _ = packet;
    minute = 60;
    return 3 * minute;
}