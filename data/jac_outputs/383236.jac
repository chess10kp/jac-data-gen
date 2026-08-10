"""
    Tries to retrieve the sfe per body part.
    The corresponding body part will be either
    the second or the third element of the body parts list.
    """
def get_sfe_per_part(sfe_map: dict[str, float], bp_list: tuple[str, str, str]) -> float {
    (_main_part, penalty_part, sfe_part) = bp_list;
    try {
        sfe = sfe_map[sfe_part];
    } except KeyError {
        sfe = sfe_map[penalty_part];
    }
    return sfe;
}