"""Convert milliseconds time to the SRT subtitles format time string."""
def millis_to_srt(millis: float) -> str {
    result = '';
    milliseconds = millis % 1000;
    result = ('%03d' % milliseconds) + result;
    millis = (millis - milliseconds) / 1000;
    seconds = millis % 60;
    result = ('%02d,' % seconds) + result;
    millis = (millis - seconds) / 60;
    minutes = millis % 60;
    result = ('%02d:' % minutes) + result;
    millis = (millis - minutes) / 60;
    result = ('%02d:' % millis) + result;
    return result;
}