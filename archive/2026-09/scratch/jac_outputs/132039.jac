"""
Computes overall formula features score.

It discriminates the contributions between features. Semantic and
structural features are more important than constant and variable
features and thus given more weights.
"""
def compute_total_matching_score(
    sem_score_norm: float,
    struc_score_norm: float,
    cn_score_norm: float,
    var_score_norm: float,
    a: float = 0.2
) -> float {
    return (
        (1 - a) * (sem_score_norm + struc_score_norm)
        + a * (cn_score_norm + var_score_norm)
    ) / 2.0;
}