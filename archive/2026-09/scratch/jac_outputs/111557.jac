"""eta( r_net_day, evaporative_fraction, temperature)"""
def eta(r_net_day: float, evaporative_fraction: float, temperature: float) -> float {
    t_celsius = temperature - 273.15;
    latent = 86400.0 / ((2.501 - 0.002361 * t_celsius) * pow(10, 6));
    return r_net_day * evaporative_fraction * latent;
}