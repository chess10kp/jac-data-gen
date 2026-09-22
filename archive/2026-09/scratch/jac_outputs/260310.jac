"""
    [Eq. 5.61]
    :param chi_LT_fi: Reduction factor for lateral-torsion buckling in the fire design situation
    :param W_y: Sectional modulus (plastic for class 1 steel)
    :param k_y_theta_com: Reduction factor for yield strength at elevated temperature
    :param f_y: Steel yield strength
    :param gamma_M_fi: Partial safety factor
    :return M_b_fi_t_Rd: The resistant lateral torsion bending moment
    """
def _M_b_fi_t_Rd(
    chi_LT_fi: float, W_y: float, k_y_theta_com: float, f_y: float, gamma_M_fi: float
) -> float {
    chi_LT_fi * W_y * k_y_theta_com * f_y / gamma_M_fi
}