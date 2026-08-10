"""Split hbonds into those involving residues only and those mediated by water."""
def residue_vs_water_hbonds(hbonds: list[tuple[int, str, str, int]], solvent_resn: str) -> tuple[list[tuple[int, str, str, int]], list[tuple[int, str, str, int]]] {
    residue_hbonds = [];
    water_hbonds = [];
    for hbond in hbonds {
        (frame_idx, atom1_label, atom2_label, itype) = hbond;
        if solvent_resn in atom1_label or solvent_resn in atom2_label {
            water_hbonds.append(hbond);
        } else {
            residue_hbonds.append(hbond);
        }
    }
    return (residue_hbonds, water_hbonds);
}