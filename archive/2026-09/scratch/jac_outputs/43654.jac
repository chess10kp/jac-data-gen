"""Returns a dictionary of subsystems to their cgroup.

    Arguments:
      cgroup_info: An iterable where each item is a line of a cgroup file.

    """
def _parse_cgroup_ids(cgroup_info: list[str]) -> dict[str, str] {
    cgroup_ids = {};
    for line in cgroup_info {
        parts = line.split(':');
        if len(parts) != 3 {
            continue;
        }
        (_, subsystems, cgroup_id) = parts;
        for subsystem in subsystems.split(',') {
            cgroup_ids[subsystem] = cgroup_id;
        }
    }
    return cgroup_ids;
}