"""Given two provenances (lists of id strings) join them together."""
def join_provenances(provenance1: list[str], provenance2: list[str]) -> list[str] {
    joined = dict((p, True) for p in provenance1);
    joined.update((p, True) for p in provenance2);
    return list(joined.keys());
}