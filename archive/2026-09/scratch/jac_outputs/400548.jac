"""
Models the pileup energy based on a trapezoidal filter. We have 4 scenarios for the pileup.
The final energy depends on when the pileup signal peaks:
    1. fully inside the gap of the first signal,
    2. between the gap and the rise time of the first signal,
    3. fully inside the first signal's peak,
    4. or at the end of the first signal's peak.
"""
def model_trapezoidal_pulses(
    pileup_time: float,
    energy1: float,
    energy2: float,
    cfg: dict[str, dict[str, float]]
) -> float | None {
    if pileup_time <= cfg['filter']['gap'] - cfg['signal']['rise_time'] {
        return energy1 + energy2;
    }
    if cfg['filter']['gap'] - cfg['signal']['rise_time'] < pileup_time <= cfg['filter']['gap'] {
        x = pileup_time + cfg['signal']['rise_time'] - cfg['filter']['gap'];
        y = x * energy2 / cfg['signal']['rise_time'];
        a = x * y / 2;
        return energy1 + (energy2 * cfg['filter']['length'] - a) / cfg['filter']['length'];
    }
    if cfg['filter']['gap'] < pileup_time <= cfg['filter']['gap'] + cfg['filter']['length'] - cfg['signal']['rise_time'] {
        return energy1 + (
            (cfg['filter']['length'] + cfg['filter']['gap']) - pileup_time - 0.5 * cfg['signal']['rise_time']
        ) * energy2 / cfg['filter']['length'];
    }
    if cfg['filter']['gap'] + cfg['filter']['length'] - cfg['signal']['rise_time'] < pileup_time <= cfg['filter']['gap'] + cfg['filter']['length'] {
        x = cfg['filter']['length'] + cfg['filter']['gap'] - pileup_time;
        y = x * energy2 / cfg['signal']['rise_time'];
        return energy1 + x * y * 0.5 / cfg['filter']['length'];
    }
}