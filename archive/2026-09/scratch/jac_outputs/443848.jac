"""
    Given a genotype given by cyvcf2, translate this to a valid genotype string.
    """
def resolve_cyvcf2_genotype(cyvcf2_gt: tuple[int, int, int]) -> str {
    separator = "|" if cyvcf2_gt[2] else "/";
    a_1 = "." if cyvcf2_gt[0] == -1 else str(cyvcf2_gt[0]);
    a_2 = "." if cyvcf2_gt[1] == -1 else str(cyvcf2_gt[1]);
    return a_1 + separator + a_2;
}