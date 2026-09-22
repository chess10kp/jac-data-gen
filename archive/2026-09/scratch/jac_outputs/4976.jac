"""
    MUTATION FREQUENCY

    Calculates the mutation frequency from haplotype count and distance matrix.
    """
def mutation_frequency(H: int, D: list[list[float]]) -> float {
    sumd = 0.0;
    for i in range(H) {
        sumd += D[0][i];
    }
    return sumd / float(H);
}