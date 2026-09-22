"""Returns class labels from indexes min(1, min(labels_map)) through max(labels_map)."""
def get_class_labels(labels_map: dict[int, str]) -> list[str] {
    mini = min(1, min(labels_map));
    maxi = max(labels_map);
    return [labels_map.get(i, f"class {i}") for i in range(mini, maxi + 1)];
}