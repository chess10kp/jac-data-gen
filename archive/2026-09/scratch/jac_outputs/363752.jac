"""Normalize a dataset name."""
def dataset_name_normalization(name: str) -> str {
    return name.lower().replace('_', '');
}