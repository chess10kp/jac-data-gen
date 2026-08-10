""" Truncates the gene to only target splice sites """
def truncateToSplice(exons: Any) -> object {
    splice_sites = [];
    for ind in range(0, len(exons)) {
        splice_sites.append([exons[ind][0], (exons[ind][1] - 1), (exons[ind][1] + 1)]);
        splice_sites.append([exons[ind][0], (exons[ind][2] - 1), (exons[ind][2] + 1)]);
    }
    return splice_sites[1:(len(splice_sites) - 1)];
}