"""Calculate the accuracy between predictions."""
def accuracy(labels: list[int | list[int]], preds: list[int]) -> float {
    correct = 0;
    for (idx, label) in enumerate(labels) {
        pred = preds[idx];
        if isinstance(label, int) {
            if label == pred {
                correct += 1;
            }
        } elif pred in label {
            correct += 1;
        }
    }
    return correct / len(labels);
}