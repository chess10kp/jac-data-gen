"""Convert time in seconds to a human readable string"""
def _hr_time(seconds: int | float) -> str {
    minutes = seconds // 60;
    if not minutes {
        return '{}s'.format(seconds);
    }
    hours = minutes // 60;
    if not hours {
        seconds -= minutes * 60;
        return '{}m {}s'.format(minutes, seconds);
    }
    days = hours // 24;
    if not days {
        minutes -= hours * 60;
        return '{}h {}m'.format(hours, minutes);
    }
    years = days // 365;
    if not years {
        hours -= days * 24;
        return '{}d {}h'.format(days, hours);
    }
    days -= years * 365;
    return '{}y {}d'.format(years, days);
}