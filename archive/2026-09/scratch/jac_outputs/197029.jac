"""
    Generate full taxonomic lineage from a taxid
    Args:
        taxid (str): taxid
        names_map (dict[str:str]): the taxonomic names for each taxid node
        ranks_map (dict[str:str]): the parent node for each taxid
    Returns:
        taxonomy (str): full taxonomic lineage string

    """
def get_full_name(taxid: str, names_map: dict[str, str], ranks_map: dict[str, str]) -> str {
    taxid_lineage = list();
    while True {
        taxid_lineage.append(taxid);
        if taxid not in ranks_map {
            break;
        }
        new_taxid = ranks_map[taxid];
        if taxid == new_taxid {
            break;
        } else {
            taxid = new_taxid;
        }
    }
    names_lineage = [names_map[t] for t in taxid_lineage];
    return ";".join(reversed(names_lineage));
}