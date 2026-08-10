"""
    Format chrom name to keep the chroms used in this script in the same style
    """
def __format_chrom(chrom: str) -> str {
    return chrom[3:] if chrom.startswith("chr") else chrom;
}