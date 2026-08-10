"""Calculate power loss in the transistor."""
def transistor_power(vcc_max: float, i_out: float, r_load: float, r_set: float) -> float {
    r_tot = r_load + r_set;
    max_pwr_i = vcc_max / (2 * r_tot);
    load_rdrop = max_pwr_i * r_tot;
    v_trans = vcc_max - load_rdrop;
    return max_pwr_i * v_trans;
}