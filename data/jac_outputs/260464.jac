"""Validate key in database reaction entry"""
def _check_validity_specie_tag_in_reaction_dict(k: str) -> bool {
    return k not in ("type", "id_db", "log_K25", "log_K_coefs", "deltah", "phase_name", "Omega", "T_c", "P_c", "Vm");
}