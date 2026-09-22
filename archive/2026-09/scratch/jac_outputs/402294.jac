"""Emitter injection efficiency: fraction of emitter current from desired carriers."""
def emitter_injection_efficiency(i_en: float = 0, i_e: float = 1) -> float {
    return i_en / i_e;
}