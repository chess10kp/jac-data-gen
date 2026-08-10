"""Initialize a feature section of genbank file.
    The feature section always start with the mandatory 'source' feature
    """
def init_feature(
    chromosome_size: int, organism: str, mol_type: str = 'genomic DNA'
) -> str {
    text = f'''\
FEATURES             Location/Qualifiers
     source          1..{chromosome_size}
                     /mol_type="{mol_type}"
                     /organism="{organism}"\n''';
    return text;
}