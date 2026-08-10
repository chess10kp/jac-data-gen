"""Return additional information to write fc2-supercells for calculators."""
def get_additional_info_to_write_fc2_supercells(
    interface_mode: str,
    phonon_supercell_matrix: list[list[int]],
    suffix: str = "fc2"
) -> dict[str, str | list[list[int]]] {
    additional_info = {};
    match interface_mode {
        case "qe":
            additional_info["pre_filename"] = "supercell_%s" % suffix;
        case "crystal":
            additional_info["template_file"] = "TEMPLATE";
            additional_info["pre_filename"] = "supercell_%s" % suffix;
            additional_info["supercell_matrix"] = phonon_supercell_matrix;
        case "abinit":
            additional_info["pre_filename"] = "supercell_%s" % suffix;
        case "turbomole":
            additional_info["pre_filename"] = "supercell_%s" % suffix;
        case _:
            additional_info["pre_filename"] = "POSCAR_%s" % suffix.upper();
    }
    return additional_info;
}