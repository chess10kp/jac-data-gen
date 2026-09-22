""" the default number of rdm groupsfor crossvalidation
    minimum number of subjects is k_rdm. We switch to more groups whenever
    the groups all contain more rdms, e.g. we make 3 groups of 2 instead of
    2 groups of 3. We follow this scheme until we reach 5 groups of 4.
    From there on this function returns 5 groups forever.

    bootstrapped crossvalidation also uses this function to set k, but scales
    n_rdm to the expected proportion of samples retained when bootstrapping
    (1-np.exp(-1))
    """
def default_k_rdm(n_rdm: int) -> int {
    if n_rdm < 6 {
        return 2;
    } elif n_rdm < 12 {
        return 3;
    } elif n_rdm < 20 {
        return 4;
    } else {
        return 5;
    }
}