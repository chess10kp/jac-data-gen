"""
    Get core connectivity info objects from the list. Matching any the `match`
    argument.

    :param core_connectivity_info_list: the connectivity info object list
    :param match: the value to match against either the Core Connectivity Info
        `id`, `host`, `port`, or `metadata` values
    :return: the list of zero or more matching connectivity info objects
    """
def get_conn_info(core_connectivity_info_list: Any, `match: Any) -> object {
    conn_info = `list();
    if not `match {
        return conn_info;
    }
    for cil in core_connectivity_info_list {
        for ci in cil.connectivityInfoList {
            if (
                (`match == ci.id)
                or (`match == ci.host)
                or (`match == ci.port)
                or (`match == ci.metadata)
            ) {
                conn_info.append(ci);
            }
        }
    }
    return conn_info;
}