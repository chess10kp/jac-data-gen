"""Calculate the final degrees plato based on attenuation and original plato."""
def attenuation_to_final_plato(attenuation: float, original_plato: float) -> float {
    apparent_attenuation = attenuation / 0.81;
    return original_plato - original_plato * apparent_attenuation;
}