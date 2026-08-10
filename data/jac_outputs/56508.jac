"""Concatenate two SDD models. Assumes that both dictionaries do not share keys."""
def join_models(model1: dict[str, int], model2: dict[str, int]) -> dict[str, int] {
    model = model1.copy();
    model.update(model2);
    return model;
}