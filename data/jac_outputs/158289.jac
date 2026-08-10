"""
Prune the dictionary, only attribute in colname will be left.
"""
def SelectColumn(
    lig_dict: dict[str, dict[str, object]],
    colname: list[str]
) -> dict[str, dict[str, object]] {
    lig_new = dict();
    for k in lig_dict {
        lig_new[k] = {
            sk: v
            for (sk, v) in lig_dict[k].items()
            if sk in colname
        };
    }
    return lig_new;
}