"""Create the output filename for a dataset split."""
def get_output_filename(dest_dir: str, class_name: str) -> str {
    return '%s/ON3D_%s.tfrecord' % (dest_dir, class_name);
}