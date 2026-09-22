"""check the format of file."""
def check_format(filename: str) -> int {
    allowed_format = [".fa", ".fasta", ".fa.gz", ".fasta.gz"];
    if any(f for f in allowed_format if filename.endswith(f)) {
        return 0;
    }
    msg = "file format is not in %s" % allowed_format;
    raise Exception(msg);
}