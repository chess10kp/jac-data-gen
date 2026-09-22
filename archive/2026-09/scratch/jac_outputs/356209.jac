"""
    Create a VCF representation of the genotype based on alleles. Format appropriately if haploid.

    Args:
        vcf_allele1_char (string): 0,1,2 etc.
        vcf_allele2_char (string): 0,1,2, etc.
        vcf_record (vcf._Record): Record for the entry analyzed
        ploidy(int): Expected ploidy.

    Returns
        string: String representation of genotype (e.g., "0/1"), adjusted for haploid calls if applicable
    """
def format_vcf_genotype(
    vcf_allele1_char: Any, vcf_allele2_char: Any, ploidy: Any
) -> object {
    assert (ploidy < 3);
    if (ploidy == 1) {
        if (vcf_allele1_char == vcf_allele2_char) {
            return str(vcf_allele1_char);
        }
    }
    vcf_genotype = "";
    if (vcf_allele2_char < vcf_allele1_char) {
        vcf_genotype = str(vcf_allele2_char) + "/" + str(vcf_allele1_char);
    } else {
        vcf_genotype = str(vcf_allele1_char) + "/" + str(vcf_allele2_char);
    }
    return vcf_genotype;
}