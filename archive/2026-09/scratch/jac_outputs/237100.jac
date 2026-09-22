"""Uses Boyer frequencies to find omega_mkn."""
def find_omega(
    omega_r: float,
    omega_theta: float,
    omega_phi: float,
    em: int,
    kay: int,
    en: int,
    M: float = 1
) -> float {
    return en * omega_r + em * omega_phi + kay * omega_theta;
}