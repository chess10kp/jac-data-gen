"""dBuv (dB microvolts) to uV (microvolts)."""
def dbuv_to_uV(dbuv: float) -> float {
    return 10 ** (dbuv / 20.0);
}