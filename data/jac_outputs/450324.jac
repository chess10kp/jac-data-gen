"""Samples sort key by the max. confidence."""
def _sort_key_max_confidence(sample: dict[str, list[dict[str, float]]]) -> float {
    max_confidence = float("-inf");
    for inference in sample["inferences"] {
        if inference["confidence"] > max_confidence {
            max_confidence = inference["confidence"];
        }
    }
    return max_confidence;
}