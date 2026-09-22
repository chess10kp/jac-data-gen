"""RHEmc throws errors on reading weird phenotype
    headers. This function resolves these characters.
    """
def compatiblify_phenotype_id(phenotype_id: str) -> str {
    to_replace = [' ', '|', '>', '<', '/', '\\'];
    for ch in to_replace {
        phenotype_id = phenotype_id.replace(ch, '_');
    }
    return phenotype_id;
}