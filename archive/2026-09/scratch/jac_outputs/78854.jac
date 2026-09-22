"""Get SI prefix and reduced number."""
def si_prefix(
    n: float,
    prefixes: tuple[str, ...] = ("", "k", "M", "G", "T", "P", "E", "Z", "Y"),
    block: int = 1024,
    threshold: int = 1
) -> tuple[float | int, str] {
    if n < block * threshold or len(prefixes) == 1 {
        return (n, prefixes[0]);
    }
    return si_prefix(n / block, prefixes[1:]);
}