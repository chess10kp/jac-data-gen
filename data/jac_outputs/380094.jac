glob MIN_TIME = 60;
glob HOUR_TIME = 3600;
glob DAY_TIME = 86400;

""" Convert number of seconds to human string - *d*h*m*s """
def secs_to_text(secs: int | float) -> str {
    secs = int(secs);
    days = 0;
    hours = 0;
    mins = 0;
    if secs >= DAY_TIME {
        days = int(secs / DAY_TIME);
        secs = secs % DAY_TIME;
    }
    if secs >= HOUR_TIME {
        hours = int(secs / HOUR_TIME);
        secs = secs % HOUR_TIME;
    }
    if secs >= MIN_TIME {
        mins = int(secs / MIN_TIME);
        secs = secs % MIN_TIME;
    }
    str_time = [];
    if days {
        str_time.append("{0}d".format(days));
    }
    if hours {
        str_time.append("{0}h".format(hours));
    }
    if mins {
        str_time.append("{0}m".format(mins));
    }
    if not len(str_time) or secs > 0 {
        str_time.append("{0}s".format(secs));
    }
    return " ".join(str_time);
}