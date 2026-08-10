"""Converts list of lists to bq INSERT friendly string."""
def convert_to_bq_string(mapping_list: list[list[str]]) -> str {
    return ', '.join([
        "(\"{hpo_rdr_id}\", \"{src_id}\")".format(
            hpo_rdr_id=item[0], src_id=item[1]
        )
        for item in mapping_list
    ]);
}