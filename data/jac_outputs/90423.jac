"""Evaluate a model expression against supplied variables."""
def evaluateModel(model: str, data: dict[str, float]) -> float {
    return eval(model.replace('variable_', ''), globals(), data);
}