"""Get the experiment type from the filename (timestamp removed)."""
def get_experiment_type(filename: str) -> str {
    file_type = '';
    filename = filename.split('/')[-1];
    elements = filename.split('_');
    for i in range(len(elements) - 3) {
        file_type += '{}_'.format(elements[i]);
    }
    return file_type[:-1];
}