"""
Translates HHMMSS or HHMM formatted time into seconds.
"""
def hhmmss_to_seconds(hhmmss: str) -> int {
    hhmmss_split = hhmmss.split(":");
    try {
        seconds = (
            int(hhmmss_split[0]) * 60 * 60
            + int(hhmmss_split[1]) * 60
            + int(hhmmss_split[2])
        );
    } except IndexError {
        seconds = int(hhmmss_split[0]) * 60 * 60 + int(hhmmss_split[1]) * 60;
    }
    return seconds;
}