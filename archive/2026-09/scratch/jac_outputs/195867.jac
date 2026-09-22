"""
    Returns either a string, indicating whether this is a wired, wireless,
    or loopback interface, or None if this can not be determinted.
    :param line: line of output from: ip a
    """
def get_type(line: Any) -> object {
    if ("fq_codel" in line) {
        return "wired";
    }
    if ("mq" in line) {
        return "wireless";
    }
    if ("noqueue" in line) {
        return "loopback";
    }
    return None;
}