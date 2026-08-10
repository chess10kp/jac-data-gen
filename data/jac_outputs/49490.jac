"""Converts a time in seconds to a string using days, hours, minutes and seconds."""
def human_time(time_s: int | float) -> str {
    time_s = int(time_s);
    out = [];
    days = time_s // 86400;
    if days == 1 {
        out.append('%i day' % days);
        time_s -= days * 86400;
    } elif days >= 1 {
        out.append('%i days' % days);
        time_s -= days * 86400;
    }
    hours = time_s // 3600;
    if hours >= 1 {
        out.append('%i hr' % hours);
        time_s -= hours * 3600;
    }
    minutes = time_s // 60;
    if minutes >= 1 {
        out.append('%i min' % minutes);
        time_s -= minutes * 60;
    }
    if time_s >= 1 {
        out.append('%i sec' % time_s);
    }
    return ' '.join(out);
}