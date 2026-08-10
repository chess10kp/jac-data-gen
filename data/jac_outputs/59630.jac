"""Converts variant locations in GWAS catalog format to GTEx format.

i.e. given 'chr1_64764_C_T_b38', returns '4:79296443'.
"""
def gtex_location_to_gwas_location_(gtex_location: str) -> str {
    parts = gtex_location.split("_");
    chr = parts[0][3];
    return f"{chr}:{parts[1]}";
}