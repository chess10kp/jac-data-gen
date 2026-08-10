"""TC swap shuffles temporal ordering,
    so use this sorting indices to fix it
    """
def get_orderedTC_ordering(T: int) -> list[int] {
    match T % 3 {
        case 0:
            ordering = [((x * (T // 3)) + (x // 3)) % T for x in range(T)];
        case 1:
            ordering = [(x * (((2 * T) + 1) // 3)) % T for x in range(T)];
        case _:
            ordering = [(x * ((T + 1) // 3)) % T for x in range(T)];
    }
    return ordering;
}