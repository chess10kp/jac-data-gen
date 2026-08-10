"""
test a path for % similarity

Very rough and ready, just measures the number of nodes in common, not the order or edges.

I should check the Diez paper for a better arrangement.
"""
def __path_similarity(p1: list[str], p2: list[str]) -> float {
    a = set(p1);
    b = set(p2);
    ab = a & b;
    return len(ab) / float(min(len(a), len(b))) * 100.0;
}