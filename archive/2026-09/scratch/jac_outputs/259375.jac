"""This function reverse the table."""
def reverse_table[T](tab: list[T]) -> list[T] {
    for i in range(len(tab) // 2) {
        tmp = tab[i];
        end_val = len(tab) - i - 1;
        tab[i] = tab[end_val];
        tab[end_val] = tmp;
    }
    return tab;
}