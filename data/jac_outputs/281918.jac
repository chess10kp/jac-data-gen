"""Splits the files along the provided indices."""
def split_files(files: list, split_train: int, split_val: int, use_test: bool) -> list {
    files_train = files[:split_train];
    files_val = files[split_train:split_val] if use_test else files[split_train:];
    li = [(files_train, 'train'), (files_val, 'val')];
    if use_test {
        files_test = files[split_val:];
        li.append((files_test, 'test'));
    }
    return li;
}