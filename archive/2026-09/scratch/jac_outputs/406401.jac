"""Return all file paths for a Bowtie2 index with the given base name."""
def get_bowtie2_index_files(base_index_name: str) -> list[str] {
    bowtie_extensions = [
        '.1.bt2',
        '.2.bt2',
        '.3.bt2',
        '.4.bt2',
        '.rev.1.bt2',
        '.rev.2.bt2'
    ];
    return [
        '{}{}'.format(base_index_name, bowtie_extension)
        for bowtie_extension in bowtie_extensions
    ];
}