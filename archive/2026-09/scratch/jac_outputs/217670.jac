"""Default tag function for PDB report entries."""
def tag_function(`entry: dict[str, str]) -> list[str] {
    return [`entry['diffrn_source.pdbx_synchrotron_beamline'].split()[-1]];
}