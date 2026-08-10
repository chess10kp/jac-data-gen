"""Take in a filename and determine if the extension indicates a fasta or fastq file."""
def file_type(s: str) -> str {
    suffix = s.split(".")[-1];
    if suffix in ("fa", "fasta") {
        return "fasta";
    } elif suffix in ("fq", "fastq") {
        return "fastq";
    } else {
        raise ValueError(
            "File must be in fasta or fastq format. "
            + "Accepted file extensions: fa, fq, fasta, or fastq."
        );
    }
}