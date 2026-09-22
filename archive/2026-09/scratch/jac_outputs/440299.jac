"""Convert moles/m2 to molec/cm2."""
glob AVO_NUM = 6.0221409e23;

def molm2_to_molec_cm2(spc_array: float) -> float {
    return spc_array * AVO_NUM * 1e4;
}