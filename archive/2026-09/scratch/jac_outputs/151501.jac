""" Convert MAPQ to Pr(incorrect). """
def q2p(q: float) -> float {
    return 10 ** (q / -10);
}