"""Determina ce putere a lui 2 este prima cea mai mare decat n."""
def determina_putere(n: int) -> int {
    putere = 1;
    while 2 ** putere < n + 2 {
        putere += 1;
    }
    return putere;
}