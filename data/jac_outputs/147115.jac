"""Match RNA to DNA region and append new information to RNA_dic."""
def match_RNA_to_DNA(
    rna_dic: dict[str, dict[str, int | str]],
    region_dic: dict[str, dict[str, int | str]],
    max_size_th: int = 100000
) -> dict[str, dict[str, int | str]] {
    updated_dic = {k: v for (k, v) in rna_dic.items()};
    for (k, rdic) in updated_dic.items() {
        for (rid, region) in region_dic.items() {
            if (
                abs((rdic['end'] as int) - (rdic['start'] as int))
                and (rdic['start'] as int) >= (region['start'] as int)
                and (rdic['start'] as int) <= (region['end'] as int)
                and rdic['chr'] == region['chr']
            ) {
                updated_dic[k]['DNA_id'] = rid;
            }
        }
    }
    return updated_dic;
}