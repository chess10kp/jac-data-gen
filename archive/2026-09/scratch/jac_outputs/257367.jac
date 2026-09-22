"""
This function converts the user given molecule names separated by semicolon into a list of string
INPUT: molecule_name(Molecule names in semicolon separated format. Example: Methane;Methanol;Ethane)
OUTPUT: molecule_names(Molecule names in list of string format. Example: ['Methane','Methanol','Ethane'])
"""
def takeInputAsList(molecule_name: str) -> list[str] {
    return molecule_name.split(';');
}