"""Creates the output filename."""
def _get_output_filename(dataset_dir: str, split_name: str) -> str {
    return '%s/cifar10_%s.tfrecord' % (dataset_dir, split_name);
}