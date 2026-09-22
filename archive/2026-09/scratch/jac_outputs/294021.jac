"""Merge baseline learner f_0 into F without filtering."""
def no_filter(
    f_0: object,
    F: list[object],
    X_target: list[list[float]],
    y_target: list[float],
    metric: str | None = None,
    vote_func: object | None = None
) -> list[object] {
    F.append(f_0);
    return F;
}