"""Computes the flicker percentage of the waveform."""
def percent_flicker(v_max: float, v_pp: float) -> float {
    return v_pp / v_max * 100;
}