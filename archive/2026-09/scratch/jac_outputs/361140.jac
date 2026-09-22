"""
    Uses Boyer frequencies to find omega_mkn

    Parameters:
        omega_r (float): radial boyer lindquist frequency
        omega_theta (float): theta boyer lindquist frequency
        omega_phi (float): phi boyer lindquist frequency
        em (int): phi mode
        kay (int): theta mode
        en (int): radial mode

    Keyword Args:
        M (float): mass of large body

    Returns:
        omega (float): frequency of motion
    """
def fp_find_omega(
    omega_r: float,
    omega_theta: float,
    omega_phi: float,
    em: int,
    kay: int,
    en: int,
    M: float = 1
) -> float {
    en * omega_r + em * omega_phi + kay * omega_theta
}