"""Return the potential of the most electronegative element in a list of elements"""
def choose_most_elec_neg_potential(elem_lst: list[str], potential_dict: dict[str, float]) -> float | None {
    if not elem_lst or len(potential_dict) == 1 {
        return None;
    }
    return potential_dict[elem_lst[0]];
}