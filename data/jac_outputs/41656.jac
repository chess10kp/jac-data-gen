"""Check if each exon of a given transcript ID is covered by > 0 reads.

If so return True, else False.
"""
def check_tr_id_full_coverage(
    tr_id: str,
    trid2exc_dic: dict[str, int],
    regid2nc_dic: dict[str, float],
    pseudo_counts: bool = False
) -> bool {
    min_ex_cov = 0;
    if pseudo_counts {
        min_ex_cov = 1;
    }
    for i in range(trid2exc_dic[tr_id]) {
        ex_nr = i + 1;
        ex_id = tr_id + "_e" + str(ex_nr);
        ex_cov = regid2nc_dic[ex_id];
        if ex_cov == min_ex_cov {
            return False;
        }
    }
    return True;
}