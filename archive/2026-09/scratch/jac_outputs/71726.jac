"""
Computes the requested maintenance rate from
mg the maintenance free energy trait and the catabolic energy
**REF**
"""
def Mreq(mg: float, deltaGcat: float) -> float {
    return -mg / deltaGcat;
}