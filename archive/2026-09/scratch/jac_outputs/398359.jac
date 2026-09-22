"""Find permutation mapping unpermuted groups g to permuted groups gp."""
def _find_permutation_of_group(g: list[int], gp: list[int]) -> list[int] {
    n = len(g);
    perm = [];
    `skip = [];
    for i in range(n) {
        `skip.append(False);
    }
    for im in range(n) {
        for jm in range(n) {
            if `skip[jm] {
                continue;
            }
            if gp[jm] == g[im] {
                perm.append(jm);
                `skip[jm] = True;
                break;
            }
        }
    }
    return perm;
}