""" determine if pf is done with tau """
def tau_pf(spc_mod_dct_i: dict[str, dict[str, str]]) -> bool {
    tors_model = spc_mod_dct_i['tors']['mod'];
    return tors_model in ('tau', 'tau-1dhr', 'tau-1dhrf', 'tau-1dhrfa');
}