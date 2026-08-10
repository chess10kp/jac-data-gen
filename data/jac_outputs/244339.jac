"""Remove GO IDs from the association, return a reduced association."""
def remove_assc_goids(assoc: dict[str, set[str]], broad_goids: set[str]) -> dict[str, dict[str, set[str]] | set[str]] {
    actually_removed_goids = set();
    actually_removed_genes = set();
    assc_rm = {};
    for (geneid, goid_set) in assoc.items() {
        rm_gos = goid_set.intersection(broad_goids);
        if rm_gos {
            actually_removed_goids.update(rm_gos);
            reduced_goids = goid_set.difference(rm_gos);
            if reduced_goids {
                assc_rm[geneid] = reduced_goids;
            } else {
                actually_removed_genes.add(geneid);
            }
        } else {
            assc_rm[geneid] = goid_set;
        }
    }
    return {
        'assoc_reduced': assc_rm,
        'goids_removed': actually_removed_goids,
        'genes_removed': actually_removed_genes
    };
}