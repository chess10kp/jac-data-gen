"""Define how many cell switches (DCell) and PODs (FatTree) wil be created on each cluster node or worker."""
def arrayNetworkLength(networkLength: int, clusterNodesLength: int) -> list[float] {
    lengths = [networkLength / clusterNodesLength] * clusterNodesLength;
    rest_network_length = networkLength % clusterNodesLength;
    for i in range(rest_network_length) {
        lengths[i] = lengths[i] + 1;
    }
    return lengths;
}