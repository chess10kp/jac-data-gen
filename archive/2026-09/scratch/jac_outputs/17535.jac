"""Format a seconds value into a human-readable form."""
def format_seconds(s: int) -> str {
    (years, s) = divmod(s, 31556952) as tuple[int, int];
    (min, s) = divmod(s, 60) as tuple[int, int];
    (h, min) = divmod(min, 60) as tuple[int, int];
    (d, h) = divmod(h, 24) as tuple[int, int];
    return '%sy, %sd, %sh, %sm, %ss' % (years, d, h, min, s);
}