"""Compute intensity of the first isotopologue M0.

Handle element X with specific abundance.

Parameters
----------
formula : pyteomics.mass.Composition
    Chemical formula, as a dict of the number of atoms for each element:
    {element_name: number_of_atoms, ...}.
abundance : dict
    Dictionary of abundances of isotopes:
    {"element_name[isotope_number]": relative abundance, ..}.

Returns
-------
float
    Value of M0.

Notes
-----
X represents C with default isotopic abundance.

"""
def compute_M0_nl(formula: dict[str, int], abundance: dict[str, float]) -> float {
    return (
        abundance["C[12]"] ** formula["C"]
        * abundance["X[12]"] ** formula["X"]
        * abundance["H[1]"] ** formula["H"]
        * abundance["N[14]"] ** formula["N"]
        * abundance["O[16]"] ** formula["O"]
        * abundance["S[32]"] ** formula["S"]
    );
}