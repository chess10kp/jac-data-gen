"""
    Function that returns the names of the parameters for writing to the dataframe after the fit.
    num_pars is the number of parameters in the fit. 1,3,5,7,9 are the num_params that constrain the fit.
    while the even numbers are the parameters for the functions that don't constrain the fits.
    """
def _return_parameter_names(num_pars: int) -> list[str] {
    match num_pars {
        case 1:
            return ['C_a', 'tau_a'];
        case 2:
            return ['C_a', 'tau_a'];
        case 3:
            return ['C_a', 'tau_a', 'tau_b'];
        case 4:
            return ['C_a', 'tau_a', 'C_b', 'tau_b'];
        case 5:
            return ['C_a', 'tau_a', 'C_b', 'tau_b', 'tau_g'];
        case 6:
            return ['C_a', 'tau_a', 'C_b', 'tau_b', 'C_g', 'tau_g'];
        case 7:
            return ['C_a', 'tau_a', 'C_b', 'tau_b', 'C_g', 'tau_g', 'tau_d'];
        case 8:
            return ['C_a', 'tau_a', 'C_b', 'tau_b', 'C_g', 'tau_g', 'C_d', 'tau_d'];
        case 9:
            return [
                'C_a',
                'tau_a',
                'C_b',
                'tau_b',
                'C_g',
                'tau_g',
                'C_d',
                'tau_d',
                'tau_e'
            ];
        case 10:
            return [
                'C_a',
                'tau_a',
                'C_b',
                'tau_b',
                'C_g',
                'tau_g',
                'C_d',
                'tau_d',
                'C_e',
                'tau_e'
            ];
        case _:
            return [];
    }
}