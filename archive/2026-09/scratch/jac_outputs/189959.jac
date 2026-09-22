"""Convert hectopascals to inches of mercury."""
def hPa_to_inHg(p_hPa: float | None) -> float | None {
    if p_hPa is None {
        return None;
    }
    return p_hPa / 33.86389;
}