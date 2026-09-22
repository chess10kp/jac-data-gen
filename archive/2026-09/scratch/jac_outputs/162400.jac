"""Vrati index rodice prvku na pozici 'i'.
Pokud neexistuje, vrati None.
"""
def parent_index(i: int) -> int | None {
    return (i - 1) // 2 if i > 0 else None;
}