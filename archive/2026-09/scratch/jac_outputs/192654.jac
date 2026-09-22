"""
    Computes the mass of total input plasmid mass required to get a given mass
    of target DNA.

    Silently assumes that the units are:
    - target_len: bp (base pairs)
    - plasmid_len: bp (base pairs)
    - target_mass: ng (nanograms)
    """
def input_plasmid_mass(target_len: float, plasmid_len: float, target_mass: float) -> float {
    return target_mass * plasmid_len / target_len;
}