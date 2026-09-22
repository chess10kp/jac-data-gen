"""Modified to calculate average quality score of a sequence."""
def qual_stat(qstr: bytes) -> float {
    q30_sum = 0;
    for q in qstr {
        qual = q - 33;
        q30_sum += qual;
    }
    return q30_sum / len(qstr);
}