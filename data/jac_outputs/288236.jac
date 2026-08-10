"""
    Determine the chromosomes in a cluster of hotspot regions
    """
def chromosomesInCluster(cluster: list[dict[str, str | int]]) -> dict[str, tuple[int, int]] {
    chromosomes: dict[str, tuple[int, int]] = dict();
    for point in cluster {
        chromosome = point['chromosome'] as str;
        position = point['position'] as int;
        if chromosome in chromosomes {
            (start, end) = chromosomes[chromosome];
            chromosomes[chromosome] = (min(start, position), max(end, position + 1));
        } else {
            chromosomes[chromosome] = (position, position + 1);
        }
    }
    return chromosomes;
}