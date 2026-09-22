"""bubble sorter."""
def bubsort(a: list[int]) -> list[int] {
    need = True;
    while need {
        need = False;
        for i in range(len(a) - 1) {
            if a[i] > a[i + 1] {
                (a[i], a[i + 1]) = (a[i + 1], a[i]);
                need = True;
            }
        }
    }
    return a;
}