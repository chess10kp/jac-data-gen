"""Return the number of bytes n in more human readable form."""
def human_bytes(n: int) -> str {
    if n < 1024 {
        return f'{n} B';
    }
    k = n / 1024;
    if k < 1024 {
        return f'{round(k)} KB';
    }
    m = k / 1024;
    if m < 1024 {
        return f'{m:.1f} MB';
    }
    g = m / 1024;
    return f'{g:.2f} GB';
}