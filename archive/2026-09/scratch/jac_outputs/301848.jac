"""
Parameters
----------
peptide : list
    Peptide sequence
m: modification label to apply
sites : set
    Amino acids eligible for modification

Returns
-------
set of lists
"""
def peptide_isoforms(
    peptide: list[str], m: str, sites: set[str], prev_aa: str, next_aa: str
) -> list[tuple[str, ...]] {
    isoforms: list[tuple[str, ...]] = [];
    if (
        (('N-term' in sites) or (('Protein N-term' in sites) and (prev_aa == '-')))
        and len(peptide[0]) == 1
        and peptide[0] not in sites
    ) {
        isoforms.append(((m + peptide[0]), ) + tuple(peptide[1:]));
    }
    if (
        (('C-term' in sites) or (('Protein C-term' in sites) and (next_aa == '-')))
        and len(peptide[-1]) == 1
        and peptide[-1] not in sites
    ) {
        isoforms.append(tuple(peptide[:-1]) + ((m + peptide[-1]), ));
    }
    for (ind, a) in enumerate(peptide) {
        if a in sites {
            isoforms.append(
                tuple(peptide[:ind]) + ((m + a), ) + tuple(peptide[(ind + 1):])
            );
        }
    }
    return isoforms;
}