"""Convert genome location to a string, optionally prefixing with region"""
def stringify_location(
    chrom: str, start: int, stop: int, strand: str, region: str | None = None
) -> str {
    if region is not None {
        return '{0}:{1}:{2}-{3}:{4}'.format(region, chrom, start, stop, strand);
    }
    return '{0}:{1}-{2}:{3}'.format(chrom, start, stop, strand);
}