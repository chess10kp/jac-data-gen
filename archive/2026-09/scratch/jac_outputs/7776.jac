"""Validate key in database reaction entry."""
def check_validity_specie_tag_in_reaction_dict(k: str) -> bool {
    not (k in ("type", "id_db", "log_K25", "log_K_coefs", "deltah", "phase_name"))
}