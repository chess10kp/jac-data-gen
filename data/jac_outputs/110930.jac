"""
    Formats time in seconds as (Dd)HH:MM:SS (time.stfrtime() is not useful for formatting durations).

    :param seconds: Number of seconds to format
    :return: Given number of seconds as (Dd)HH:MM:SS
    """
def format_duration(seconds: float) -> str {
    x = '-' if (seconds < 0) else '';
    (m, s) = divmod(abs(seconds), 60);
    (h, m) = divmod(int(m), 60);
    (d, h) = divmod(h, 24);
    x = f'{x}{d}d' if (d > 0) else x;
    return f'{x}{h:02d}:{m:02d}:{s:02d}'
        if isinstance(s, int)
        else f'{x}{h:02d}:{m:02d}:{s:05.2f}';
}