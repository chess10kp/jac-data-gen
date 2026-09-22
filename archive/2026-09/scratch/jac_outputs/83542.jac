"""Build a simplistic all-to-all mapping."""
def make_initiator_target_all2all_map(
    initiator_wwpns: list[str],
    target_wwpns: list[str]
) -> dict[str, list[str]] {
    i_t_map: dict[str, list[str]] = {};
    for i_wwpn in initiator_wwpns {
        i_t_map[str(i_wwpn)] = [];
        for t_wwpn in target_wwpns {
            i_t_map[i_wwpn].append(t_wwpn);
        }
    }
    return i_t_map;
}