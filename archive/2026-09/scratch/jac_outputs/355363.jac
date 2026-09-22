"""Convert a formal gene name to be suitable for file names."""
def gene_to_filename(gene: str) -> str {
    gene.lower().replace(' ', '')
}