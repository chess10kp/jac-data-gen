"""Convert chirp mass and symmetric mass ratio to total mass."""
def Mcnu_to_M(Mc: float, nu: float) -> float {
    return Mc * nu ** (-3.0 / 5.0);
}