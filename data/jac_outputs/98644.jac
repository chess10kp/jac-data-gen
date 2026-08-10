glob SECONDS_PER_YEAR = 31104000;
glob SECONDS_PER_MONTH = 2592000;
glob SECONDS_PER_DAY = 86400;

"""Transform a timedelta expressed in seconds into a human readable string."""
def human_readable_stat(timedelta_seconds: float, stat_locale: dict[str, str] = {}) -> str {
    timedelta_seconds = int(float(timedelta_seconds));
    years = timedelta_seconds // SECONDS_PER_YEAR;
    months = timedelta_seconds // SECONDS_PER_MONTH;
    days = timedelta_seconds // SECONDS_PER_DAY;
    hours = (timedelta_seconds // 3600) % 24;
    minutes = (timedelta_seconds // 60) % 60;
    seconds = timedelta_seconds % 60;
    if years > 0 {
        return str(years) + stat_locale.get("year", "Y");
    }
    if months > 0 {
        return str(months) + stat_locale.get("month", "MO");
    }
    if days > 0 {
        return str(days) + stat_locale.get("day", "D");
    }
    if hours > 0 {
        return str(hours) + stat_locale.get("hour", "h");
    }
    if minutes > 0 {
        return str(minutes) + stat_locale.get("minute", "m");
    }
    return str(seconds) + stat_locale.get("second", "s");
}