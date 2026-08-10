"""Provide a dictionary remapping original read indexes to new indexes.

When re-ordering the header, the individual read identifiers need to be
updated as well.
"""
def _id_remapper(orig: list[tuple[str, int]], new: list[tuple[str, int]]) -> dict[int | None, int | None] {
    new_chrom_to_index = {};
    for (i_n, (chr_n, _)) in enumerate(new) {
        new_chrom_to_index[chr_n] = i_n;
    }
    remap_indexes = {};
    for (i_o, (chr_o, _)) in enumerate(orig) {
        if chr_o in new_chrom_to_index {
            remap_indexes[i_o] = new_chrom_to_index[chr_o];
        }
    }
    remap_indexes[None] = None;
    return remap_indexes;
}