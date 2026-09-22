"""Validate labels."""
def decode_labels(labels: Any) -> object {
    labels_decode = [];
    for label in labels {
        if not isinstance(label, str) {
            if isinstance(label, int) {
                label = str(label);
            } else {
                label = label.decode('utf-8').replace('"', '');
            }
        }
        labels_decode.append(label);
    }
    return labels_decode;
}