"""Return a readable time format"""
def time_to_string(seconds: int) -> str {
    if seconds == 0 {
        return '0 seconds';
    }
    h = seconds // 3600;
    s = seconds % 3600;
    m = s // 60;
    s = s % 60;
    h_s = 'hour' if h == 1 else 'hours';
    m_s = 'minute' if m == 1 else 'minutes';
    s_s = 'second' if s == 1 else 'seconds';
    time_string = '';
    if h {
        time_string = f'{int(h)} {h_s}, {int(m)} {m_s} and {int(s)} {s_s}';
    } elif m {
        time_string = f'{int(m)} {m_s} and {int(s)} {s_s}';
    } else {
        time_string = f'{int(s)} {s_s}';
    }
    return time_string;
}