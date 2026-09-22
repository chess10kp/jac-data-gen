"""Convert byte count to display string as bytes, KB, MB or GB.

    1st parameter = # bytes (may be negative)
    Returns a short string version, such as '17 bytes' or '47.6 GB'
    """
def bytecount(numbytes: Any) -> object {
    retval = "-" if (numbytes < 0) else "";
    absvalue = abs(numbytes);
    if (absvalue < 1024) {
        retval = retval + format(absvalue, ".0f") + " bytes";
    } elif (1024 <= absvalue < (1024 * 100)) {
        retval = retval + format((absvalue / 1024), "0.1f") + " KB";
    } elif ((1024 * 100) <= absvalue < (1024 * 1024)) {
        retval = retval + format((absvalue / 1024), ".0f") + " KB";
    } elif ((1024 * 1024) <= absvalue < (1024 * 1024 * 100)) {
        retval = retval + format((absvalue / (1024 * 1024)), "0.1f") + " MB";
    } elif ((1024 * 1024 * 100) <= absvalue < (1024 * 1024 * 1024)) {
        retval = retval + format((absvalue / (1024 * 1024)), ".0f") + " MB";
    } else {
        retval = retval + format((absvalue / (1024 * 1024 * 1024)), ",.1f") + " GB";
    }
    return retval;
}