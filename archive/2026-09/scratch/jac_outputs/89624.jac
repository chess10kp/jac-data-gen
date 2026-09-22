"""Given 'misc_RNA' and 'other' we prefer 'other' as it is more specific. This
will only select 'other' if 'misc_RNA' and other are the only two current
rna_types.
"""
def correct_other_vs_misc(rna_type: set[str], _: set[str]) -> set[str] {
    if rna_type == set(['other', 'misc_RNA']) {
        return set(['other']);
    }
    return rna_type;
}