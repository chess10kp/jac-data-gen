"""Samples sort key by the minimum confidence_sd."""
def _sort_key_min_confidence_sd(sample: Any, labels: Any) -> object {
    min_confidence_sd = float("+inf");
    for inference in sample["inferences"] {
        if (labels and (inference["label"] not in labels)) {
            continue;
        }
        confidence_sd = inference.get("confidence_sd", float("+inf"));
        if (confidence_sd < min_confidence_sd) {
            min_confidence_sd = confidence_sd;
        }
    }
    return min_confidence_sd;
}