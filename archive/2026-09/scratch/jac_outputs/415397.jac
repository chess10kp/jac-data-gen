"""Split and read pdb-file line (QPREP-OUT).

     Extract and return:
        atomnumber, atomname, resname, resid)
    """
def get_pdb_atom_info(line: Any) -> object {
    atomnum = int(line[6:11]);
    atmname = line[13:17].strip();
    resname = line[17:20].strip();
    resinum = int(line[22:27]);
    return (atomnum, atmname, resname, resinum);
}