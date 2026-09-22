"""Convert time in HTK (100 ns) units to ms."""
def htk_to_ms(htk_time: float | str) -> float {
    if isinstance(htk_time, str) {
        htk_time = float(htk_time);
    }
    return htk_time / 10000.0;
}