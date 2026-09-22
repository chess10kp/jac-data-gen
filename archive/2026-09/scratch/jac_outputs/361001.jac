"""Update ``P`` such that for the updated `P'` `P' v = e_{s}`."""
def _update(s: int, _lambda: list[float], P: list[list[float]]) -> list[list[float]] {
    k = min([j for j in range(s, len(_lambda)) if _lambda[j] != 0]);
    for r in range(len(_lambda)) {
        if r != k {
            P[r] = [P[r][j] - P[k][j] * _lambda[r] / _lambda[k] for j in range(len(P[r]))];
        }
    }
    P[k] = [P[k][j] / _lambda[k] for j in range(len(P[k]))];
    (P[k], P[s]) = (P[s], P[k]);
    return P;
}