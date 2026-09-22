"""
Calculate the psychrometric constant for different types of
psychrometer at a given atmospheric pressure.

Based on FAO equation 16 in Allen et al (1998).
"""
def psy_const_of_psychrometer(psychrometer: int, atmos_pres: float) -> float {
    match psychrometer {
        case 1:
            psy_coeff = 0.000662;
        case 2:
            psy_coeff = 0.0008;
        case 3:
            psy_coeff = 0.0012;
        case _:
            raise ValueError(
                'psychrometer should be in range 1 to 3: {0!r}'.format(psychrometer)
            );
    }
    return psy_coeff * atmos_pres;
}