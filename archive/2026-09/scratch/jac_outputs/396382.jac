"""Get y coordinates of deletion markers to overlay in heatmap.

    These are the linear y coordinates used in the Plotly graph object.
    i.e., the indices of data["heatmap_y_strains"]
    """
def get_deletions_y(parsed_mutations: dict[str, dict[str, list[dict[str, str | bool]]]]) -> list[int] {
    ret = [];
    for (y, strain) in enumerate(parsed_mutations) {
        for pos in parsed_mutations[strain] {
            for mutation in parsed_mutations[strain][pos] {
                if mutation["mutation_type"] == "deletion" and not mutation["hidden_cell"] {
                    ret.append(y);
                }
            }
        }
    }
    return ret;
}