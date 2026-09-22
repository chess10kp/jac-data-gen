"""
Linear function to calculate how close the size of the cluster
is to the real epileptogenic cluster that we want to find
"""
def calc_clust_similarity(target_size: int, clust_size: int) -> float {
    if clust_size > target_size {
        if clust_size >= 2 * target_size {
            clust_size = 0;
        } else {
            clust_size = target_size - (clust_size - target_size);
        }
    }
    return clust_size / target_size;
}