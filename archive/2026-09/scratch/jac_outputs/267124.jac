""" Returns a string with "N hours ago" or "N days ago", depending how many hours """
def ago_msg(hrs: float) -> str {
    days = int(hrs / 24.0);
    minutes = int(hrs * 60);
    hrs = int(hrs);
    if minutes < 60 {
        return "{} minutes ago".format(minutes);
    }
    if hrs == 1 {
        return "1 hour ago";
    }
    if hrs < 24 {
        return "{} hours ago".format(hrs);
    }
    if days == 1 {
        return "1 day ago";
    }
    return "{} days ago".format(days);
}