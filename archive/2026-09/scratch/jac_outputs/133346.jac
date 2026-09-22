"""Trim taxon hierarchy to int_level segments."""
def trim_taxon(taxon: str, int_level: int) -> str {
    '|'.join(taxon.split('|')[:int_level])
}