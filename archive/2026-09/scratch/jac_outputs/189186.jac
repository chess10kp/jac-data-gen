"""Convert speed in m/s to pace in min/km."""
def speed_to_pace(x: float) -> int | str {
    if x == 0 {
        return 0;
    }
    p = 16.6666666 / x;
    return ':'.join([str(int(p)), str(int((p * 60) % 60)).zfill(2)]);
}