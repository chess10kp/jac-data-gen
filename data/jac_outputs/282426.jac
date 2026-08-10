"""Return synapses parsed and evaluated without errors so far."""
def evaluated_profile_li(profileli: list) -> list {
    [pro for pro in profileli if not pro.errflag]
}