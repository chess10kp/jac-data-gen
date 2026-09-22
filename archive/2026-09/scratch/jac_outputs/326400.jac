"""
    Turn a list of paths into a list of cwl-compatible and ruamel-compatible file objects.

    Additionally, sort the files in lexicographical order.

    :param bam_names: file basenames
    :param folder: file folder
    :return:
    """
def create_yaml_file_objects(bam_paths: Any) -> object {
    return [{"class": "File", "path": b} for b in bam_paths];
}