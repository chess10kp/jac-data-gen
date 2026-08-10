"""Sum a list of numbers, reporting progress at each step."""
def progress_reporting_sum(numbers: list[int | float], progress: Callable[[tuple[int, int]], None]) -> int | float {
    count = len(numbers);
    total: int | float = 0;
    for (i, number) in enumerate(numbers) {
        progress((i, count));
        total += number;
    }
    progress((count, count));
    return total;
}