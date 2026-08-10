"""Generate a frequency list from a dictionary."""
def generate_freq_list(d: dict[str, int]) -> list[tuple[int, str, int, float]] {
    total = sum(d.values());
    freq_list = sorted(d.items(), key=lambda (x: tuple[str, int]) { x[1]; }, reverse=True);
    return [
        (index + 1, key, value, round((value as int) / (total as int), 2))
        for (index, (key, value)) in enumerate(freq_list)
    ];
}