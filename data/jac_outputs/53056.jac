"""Slice data according to the instances belonging to each split."""
def slice_data[T](data: list[T], info: dict[str, int], split: str | None) -> list[T] | None {
    if split is None {
        return data;
    } elif split == 'train' {
        return data[:info['train_len']];
    } elif split == 'val' {
        train_n = info['train_len'];
        val_n = train_n + info['val_len'];
        return data[train_n:val_n];
    } elif split == 'test' {
        val_n = info['train_len'] + info['val_len'];
        test_n = val_n + info['test_len'];
        return data[val_n:test_n];
    }
    return None;
}