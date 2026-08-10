""" strip off useless zeros or return nothing if zero
        - this algorithm only good to about 1 decimal place in seconds...
    """
def present_seconds(seconds: int | float) -> str {
    if seconds == 0 {
        result = '';
    } elif seconds - int(seconds) == 0 {
        result = "%d" % int(seconds);
    } else {
        result = "%2.2f" % seconds;
        result = result.strip('0');
    }
    return result;
}