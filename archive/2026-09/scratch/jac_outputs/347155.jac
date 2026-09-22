"""Calculate the median of a list."""
def median(data: list[int | float]) -> int | float {
    data.sort();
    num_values = len(data);
    half = num_values // 2;
    if num_values % 2 {
        return data[half];
    }
    return 0.5 * (data[half - 1] + data[half]);
}