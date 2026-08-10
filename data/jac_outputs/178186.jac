"""Returns the html path to the 2FoFc electron density file on the ebi server."""
def getElectronDensityLink(pdb_code: str, diff: bool = False) -> tuple[str, str] {
    file_name = pdb_code + '.ccp4';
    if diff {
        file_name = pdb_code + '_diff.ccp4';
    }
    pdb_loc = 'https://www.ebi.ac.uk/pdbe/coordinates/files/' + file_name;
    return (file_name, pdb_loc);
}