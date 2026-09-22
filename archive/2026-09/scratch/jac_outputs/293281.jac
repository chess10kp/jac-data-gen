"""
    Create frequency fingerprint from list of fingerprints.
    """
def frequency_interaction_fingerprint(fp_list: Any) -> object {
    count_fp = [sum(i) for i in zip(*fp_list)];
    frequency_fp = [(float(i) / len(fp_list)) for i in count_fp];
    return frequency_fp;
}