"""Converts the evaluation to a dictionary of strings and floats."""
def convert_evaluations(evaluations: dict[object, float]) -> dict[str, float] {
    return {str(k): v for (k, v) in evaluations.items()};
}