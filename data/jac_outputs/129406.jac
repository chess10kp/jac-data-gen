"""
R10: Determine the surface pressure Pmax (Sec 5.5.4)
for maximum surface pressure with yield or angle controlled tightening.
"""
def R10_yield(FMTab: float, Apmin: float, PG: float) -> float {
    Pmax = 1.4 * (FMTab / Apmin);
    Sp = PG / Pmax;
    if Sp > 1.0 {
        print('Sp > {} --> PASS'.format(Sp));
    } else {
        print('Sp < {} --> FAIL'.format(Sp));
    }
    return Pmax;
}