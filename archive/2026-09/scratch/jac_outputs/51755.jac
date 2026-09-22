"""
    This function finds the children of a node from the 'ceph osd tree' and returns them as list

    Args:
        node_id (int): the id of the node for which the children to be retrieved
        osd_tree (dict): dictionary containing the output of 'ceph osd tree'

    Returns:
        list: of 'children' of a given node_id

    """
def get_child_nodes_osd_tree(node_id: Any, osd_tree: Any) -> object {
    for i in range(len(osd_tree["nodes"])) {
        if (osd_tree["nodes"][i]["id"] == node_id) {
            return osd_tree["nodes"][i]["children"];
        }
    }
}