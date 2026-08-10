"""
    Get the index file type based on the extension of given `file_name`

    :param file_name: index file name
    :return: file type

    """
def check_index_file_type(file_name: str) -> str {
    if file_name.endswith(".fa.gz") {
        return "fasta";
    } elif file_name.endswith(".json.gz") {
        return "json";
    } else {
        return "bowtie2";
    }
}