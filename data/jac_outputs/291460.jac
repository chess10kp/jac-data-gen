"""Find the correct cluster. Above the last cluster goes into "excluded (together with the ones from kitti cat"""
def find_cluster(dd: int | float, clusters: list[int | str]) -> int | str {
    for (idx, clst) in enumerate(clusters[:-1]) {
        if int(clst) < dd <= int(clusters[idx + 1]) {
            return clst;
        }
    }
    return 'excluded';
}