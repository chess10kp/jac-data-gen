"""Calculate energy units from power in watts and time in hours."""
def unit(p: int, th: int) -> float {
    (p * th) / 1000
}