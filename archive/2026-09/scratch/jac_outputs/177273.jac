"""Dot product of two numerical lists."""
def dotprod(K: list[float], L: list[float]) -> float | None {
    if len(K) == len(L) {
        try {
            return sum([(x * y) for (x, y) in zip(K, L)]);
        } except ValueError {
            print('elements of K and L are not all numeric');
            exit();
        }
    } else {
        print("K and L are not of the same length");
    }
}