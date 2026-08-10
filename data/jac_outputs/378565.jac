"""Calculate the m variability metric which is the modulation index between two fluxes.

This is proportional to the fractional variability.
See Section 5 of Mooley et al. (2016) for details, DOI: 10.3847/0004-637X/818/2/105.
"""
def calculate_m_metric(flux_a: float, flux_b: float) -> float {
    2 * ((flux_a - flux_b) / (flux_a + flux_b))
}