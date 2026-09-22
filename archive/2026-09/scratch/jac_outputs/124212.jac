"""Determine if we need to scale the potential."""
def scale_tors_pot(spc_mod_dct_i: dict[str, dict[str, dict[str, str]]], to_scale: bool) -> bool {
    onedhr_model = '1dhr' in spc_mod_dct_i['tors']['mod'];
    return bool(onedhr_model and to_scale);
}