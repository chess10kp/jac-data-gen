"""
Return calculated value of FRB's X-ray counterpart fluence,
for giant flares occurring within the range of FRB distances.
Args:
- f: Radio frequency fluence
Returns: F
FRB X-ray counterpart fluence value in erg/cm^2
"""
def fluence_x_ray_calc(f: float) -> float {
    f / 2e-05
}