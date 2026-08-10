"""This method predicts the accuracy percentage."""
def accuracy_score(actual: list[int], predicted: list[int]) -> float {
    correct = 0;
    for (a, p) in zip(actual, predicted) {
        if a == p {
            correct += 1;
        }
    }
    return correct / float(len(actual)) * 100.0;
}