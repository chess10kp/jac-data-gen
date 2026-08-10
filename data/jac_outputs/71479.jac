"""Mean of the feature vector."""
def mean(feature_vector: list[int | float]) -> float {
    sum(f for f in feature_vector) / len(feature_vector)
}