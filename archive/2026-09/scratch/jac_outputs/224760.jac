"""Prints a number of seconds in a terse, human-readable format.

    Adapted from: https://gist.github.com/thatalextaylor/7408395
    """
def pretty_time_delta(seconds: Any) -> object {
    seconds = int(seconds);
    (days, seconds) = divmod(seconds, 86400);
    (hours, seconds) = divmod(seconds, 3600);
    (minutes, seconds) = divmod(seconds, 60);
    if (days > 0) {
        return ('%dd%dh%dm%ds' % (days, hours, minutes, seconds));
    }
    if (hours > 0) {
        return ('%dh%dm%ds' % (hours, minutes, seconds));
    }
    if (minutes > 0) {
        return ('%dm%ds' % (minutes, seconds));
    }
    return ('%ds' % (seconds, ));
}