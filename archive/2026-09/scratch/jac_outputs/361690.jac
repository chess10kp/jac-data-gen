"""
    Return a variant dictionary
    """
def get_vep_variant(
    chrom: Any = '1',
    pos: Any = '1',
    ref: Any = 'A',
    alt: Any = 'G',
    annotation: Any = "ADK"
) -> object {
    variant_id = '_'.join([chrom, pos, ref, alt]);
    variant = {
        "CHROM": chrom,
        "POS": pos,
        "INFO": "Annotation={0}".format(annotation),
        'vep_info': {'A': [{"Gene": annotation, "Consequence": 'transcript_ablation'}]},
        "variant_id": variant_id
    };
    return variant;
}