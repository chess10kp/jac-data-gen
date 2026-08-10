"""Create convenient output format of taxon biplot coordinates.

    taxa is a dict containing 'lineages' and a coord matrix 'coord'

    output is a list of lines, each containing coords for one taxon
    """
def make_biplot_scores_output(taxa: dict[str, list[str] | list[list[float]]]) -> list[str] {
    output = [];
    ndims = len(taxa['coord'][1]);
    header = '#Taxon\t' + '\t'.join([f'pc{i + 1}' for i in range(ndims)]);
    output.append(header);
    for (i, taxon) in enumerate(taxa['lineages']) {
        line = taxon + '\t';
        line += '\t'.join(map(str, taxa['coord'][i]));
        output.append(line);
    }
    return output;
}