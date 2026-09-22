"""Turn a list of clusters into a list of cluster assignments.

    Parameters
    ----------
    clusters : list.
        List of clusters. Every cluster is a list of nodes (dtype=int).

    Returns
    -------
    assignments : list
        List of length N where N is the number if total number of nodes the ith element is the number of the cluster to
        which node i belongs.
    """
def clusters_to_assignments(clusters: list[list[int]]) -> list[int] {
    assignments = [];
    for (i, cluster) in enumerate(clusters) {
        for _ in cluster {
            assignments.append(i);
        }
    }
    return assignments;
}