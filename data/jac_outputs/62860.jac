"""Return an appropriate error message for an InvalidParticleError."""
def _invalid_particle_errmsg(
    argument: str | int,
    mass_numb: int | None = None,
    Z: int | None = None
) -> str {
    errmsg = f"The argument {repr(argument)} ";
    if mass_numb is not None or Z is not None {
        errmsg += "with ";
    }
    if mass_numb is not None {
        errmsg += f"mass_numb = {repr(mass_numb)} ";
    }
    if mass_numb is not None and Z is not None {
        errmsg += "and ";
    }
    if Z is not None {
        errmsg += f"integer charge Z = {repr(Z)} ";
    }
    errmsg += "does not correspond to a valid particle.";
    return errmsg;
}