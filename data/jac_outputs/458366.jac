"""Calculate the hoop (circumferential) stress in a pipe
using Barlow's formula.

Refs: https://en.wikipedia.org/wiki/Barlow%27s_formula
https://en.wikipedia.org/wiki/Cylinder_stress
"""
def pipe_hoop_stress(P: float, D: float, t: float) -> float {
    return P * D / 2 / t;
}