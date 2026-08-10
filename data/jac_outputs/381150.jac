"""Get the minimum SNR for a certain emission line."""
def get_snr(snr_min: float | dict[str, float], emission_line: str, `default: float = 3) -> float {
    if not isinstance(snr_min, dict) {
        return snr_min;
    }
    if emission_line in snr_min {
        return snr_min[emission_line];
    }
    return `default;
}