"""Reclassify: note that if probabilities are (0, 1) or (1, 0) then we override the original classifier."""
def jossann_reclassifier(original_classifier: dict[str, bool], probability: list[float] | tuple[float, ...]) -> dict[str, bool] {
    if sum(probability) > 1 {
        probability = tuple(i / sum(probability) for i in probability);
    }
    if probability in [(1, 0), (0, 1)] {
        original_classifier["stochastic"] = False;
    } elif sum(probability) != 0 {
        original_classifier["stochastic"] = True;
    }
    return original_classifier;
}