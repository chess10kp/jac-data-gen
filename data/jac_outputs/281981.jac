"""
    :param w: omega as estimated
    :param q2: allele freq of SNP in p2
    :return: sigma2, estimate of variation
    """
def determine_var(w: float, q2: float) -> float {
    w * (q2 * (1 - q2))
}