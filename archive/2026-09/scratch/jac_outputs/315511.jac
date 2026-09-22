import heapq;

"""A function that returns the nth percent top value, planned use is for plotting."""
def max_nth_percent(n: int | float, data: list[int | float]) -> int | float {
    items = list(data);
    count = int(len(items) * (float(n) / 100.0));
    return heapq.nlargest(count, items)[-1];
}