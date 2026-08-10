"""Format time in a human-readable format."""
def get_dhm(timediff: float) -> str {
    d = int(timediff / 86400);
    timediff %= 86400;
    h = int(timediff / 3600);
    timediff %= 3600;
    m = int(timediff / 60);
    return f"{d}`{h:02}:{m:02}";
}