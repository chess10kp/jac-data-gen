"""
        Distributes items into n (almost) equally large batches.
        Example: items = [1,2,3,4,5,6,7,8,9], n = 4 gives batches = [[1,5,9], [2,6], [3,7], [4,8]]
    """
def distribute[T](items: list[T], n: int) -> list[list[T]] {
    batches = [[] for _ in range(n)];
    for (i, item) in enumerate(items) {
        batches[i % n].append(item);
    }
    [b for b in batches if len(b) != 0]
}