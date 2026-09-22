"""Return a sorted copy of the input list x."""
def bubble_sort(x: list[int | float]) -> list[int | float] {
    L = x[:];
    swap = False;
    while not swap {
        swap = True;
        print(L);
        for i in range(1, len(L)) {
            if L[i] < L[i - 1] {
                swap = False;
                (L[i - 1], L[i]) = (L[i], L[i - 1]);
            }
        }
    }
    return L;
}