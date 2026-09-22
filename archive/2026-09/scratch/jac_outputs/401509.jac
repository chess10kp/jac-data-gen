"""Returns the log of the thermoelectric figure of merit."""
def compute_log_zT(
    log_rho: float, log_seebeck: float, log_kappa: float, log_temperature: float
) -> float {
    return 2 * log_seebeck + log_temperature - log_rho - log_kappa;
}