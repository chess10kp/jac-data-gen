"""Returns a set of label strings for the given targets."""
def targets_to_labels(targets: list) -> set[str] {
    {str(target.label) for target in targets}
}