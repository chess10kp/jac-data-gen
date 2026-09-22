"""Shuffles two elements, indicated by `idx1` and `idx2`, between two datasets in `dataset_dict`."""
def shuffle_datasets(
    dataset_dict: dict[str, list],
    dataset_names: list[str],
    idx1: int,
    idx2: int
) -> dict[str, list] {
    for name in dataset_names {
        (dataset_dict[name][idx1], dataset_dict[name][idx2]) = (
            dataset_dict[name][idx2],
            dataset_dict[name][idx1]
        );
    }
    return dataset_dict;
}