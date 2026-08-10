"""
create one row for the log
['v1-v2', dist, dist, ...]
"""
def get_state(`edge: tuple[str, str], distances: dict[int, int]) -> list[str | int] {
    edge_s = ['(' + `edge[0] + '-' + `edge[1] + ')'];
    distances_l = [distances[i] for i in sorted(distances.keys())];
    state = edge_s + distances_l;
    return state;
}