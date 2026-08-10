"""
Compute beta = beta_normalized * N / M from the Higgins 2017 bVAE relationship
beta_norm = (beta * M) / N.
"""
def beta_from_normalized_beta(beta_normalized: float, N: int, M: int) -> float {
    return beta_normalized * N / M;
}