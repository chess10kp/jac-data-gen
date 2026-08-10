"""Returns True if dual phase mode is enabled, False otherwise."""
def epc_calc_dual_phase(reg_dict: dict[str, list[int]]) -> bool {
    return (
        reg_dict["mod_sel"][2] == 0
        and reg_dict["num_dcs"][2] == 1
        and reg_dict["pixel_mode"][2] == 1
        and reg_dict["dual_int_mode"][2] == 1
    );
}