"""Return R-groups represented by the chosen B-groups from both ligands."""
def get_rs_chosen_from_bs(
    bs_chosen: list[str],
    b_to_r_master_dict_1: dict[str, list[str]],
    b_to_r_master_dict_2: dict[str, list[str]]
) -> list[str] {
    rs_chosen = [];
    for b in bs_chosen {
        lig_number = b[0];
        _ = b[2];
        if lig_number == str(1) {
            rs_chosen.extend(b_to_r_master_dict_1[b]);
        } elif lig_number == str(2) {
            rs_chosen.extend(b_to_r_master_dict_2[b]);
        }
    }
    return rs_chosen;
}