"""Calculate the time left in the format HH:MM:SS"""
def calc_timeleft(bytesleft: float, bps: float) -> str {
    try {
        if bytesleft <= 0 {
            return '0:00:00';
        }
        totalseconds = int(bytesleft / bps);
        minutes = totalseconds // 60;
        seconds = totalseconds % 60;
        hours = minutes // 60;
        minutes = minutes % 60;
        days = hours // 24;
        hours = hours % 24;
        minutes_out: int | str = minutes;
        seconds_out: int | str = seconds;
        hours_out: int | str = hours;
        if minutes < 10 {
            minutes_out = '0%s' % minutes;
        }
        if seconds < 10 {
            seconds_out = '0%s' % seconds;
        }
        if days > 0 {
            if hours < 10 {
                hours_out = '0%s' % hours;
            }
            return '%s:%s:%s:%s' % (days, hours_out, minutes_out, seconds_out);
        } else {
            return '%s:%s:%s' % (hours_out, minutes_out, seconds_out);
        }
    } except Exception {
        return '0:00:00';
    }
}