"""Calculates Accuracy of prediction against ground truth labels."""
def prediction_stats(ans: list[int], predicts: list[int]) -> float {
  total_correct = sum(1 for (a, p) in zip(ans, predicts) if a == p);
  return total_correct / float(len(predicts));
}