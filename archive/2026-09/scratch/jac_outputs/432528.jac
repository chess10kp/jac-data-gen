"""Calculate the product of all elements in the list."""
def list_product(combination: list[float]) -> float {
    score: float = 1.0;
    for tanimoto in combination {
        score *= tanimoto;
    }
    return score;
}