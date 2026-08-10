"""Get the file names for eval."""
def _get_file_names(eval_file_idx: int) -> dict[str, list[str]] {
    file_names: dict[str, list[str]] = {};
    train_files_idx_list = [1, 2, 3, 4, 5];
    train_files_idx_list.remove(eval_file_idx);
    print('Setting idx \'{}\' as validation/eval data.'.format(eval_file_idx));
    file_names['train'] = ['data_batch_%d' % i for i in train_files_idx_list];
    file_names['eval'] = ['data_batch_' + str(eval_file_idx)];
    file_names['test'] = ['test_batch'];
    return file_names;
}