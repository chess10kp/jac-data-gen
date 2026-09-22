"""Defines ODE function conversion of Amb_mRNA to protein."""
def Protein_translation_RNA(
    t: float, y: float, L: float, U: float, D: float, mRNA: float
) -> float {
    return (L * mRNA) / (1.0 + y / D) - U * y;
}