"""Get reverse complementary sequence."""
def revcompSeq(seq: str) -> str {
    return seq.translate(str.maketrans("ACGTN", "TGCAN"))[::-1];
}