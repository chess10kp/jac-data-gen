"""Calculate the accuracy score given mean silhouette coverage of the graph."""
def get_accuracy_score(mean_silhouette_coverage: float) -> float {
    return 0.5 + 0.5 * mean_silhouette_coverage;
}