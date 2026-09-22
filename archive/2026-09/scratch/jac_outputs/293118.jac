"""Samples sort key by the min. confidence_sd."""
def _sort_key_min_confidence_sd(sample: dict[str, list[dict[str, float]]]) -> float {
    min_confidence_sd = float("+inf");
    for inference in sample["inferences"] {
        confidence_sd = inference.get("confidence_sd", float("+inf"));
        if confidence_sd < min_confidence_sd {
            min_confidence_sd = confidence_sd;
        }
    }
    return min_confidence_sd;
}