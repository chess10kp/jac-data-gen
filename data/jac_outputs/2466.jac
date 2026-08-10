"""Convert a colon-separated time string (HH:MM:SS) to seconds since midnight."""
def HHMMSS_to_seconds(string: str) -> int {
    (hhs, mms, sss) = string.split(':');
    return (int(hhs) * 60 + int(mms)) * 60 + int(sss);
}