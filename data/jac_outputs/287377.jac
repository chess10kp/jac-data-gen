"""Multi-key value assign."""
def dmka[K, V](D: dict[K, V], Ds: dict[K, V]) -> dict[K, V] {
    for (k, v) in Ds.items() {
        D[k] = v;
    }
    return D;
}