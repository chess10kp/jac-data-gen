"""Bubble the max number to the end of the list on each iteration."""
def bubble_sort(l: list[int], debug: bool = True) -> list[int] {
    for i in range(len(l)) {
        for j in range(len(l) - i - 1) {
            if l[j] > l[j + 1] {
                (l[j], l[j + 1]) = (l[j + 1], l[j]);
            }
        }
        if debug {
            print('iteration {}'.format(i), l);
        }
    }
    return l;
}