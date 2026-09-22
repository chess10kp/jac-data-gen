"""calculate accuracy of the dataset comparing the actual test label vs the predicted label"""
def accuracy_metric(actual: list[int], predicted: list[int], correct: int = 0) -> float {
    for (a, p) in zip(actual, predicted) {
        if a == p {
            correct += 1;
        }
    }
    return correct / len(actual) * 100.0;
}