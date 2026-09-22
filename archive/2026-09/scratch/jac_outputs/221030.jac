"""Parse cluster from device ID"""
def extract_cluster_from_device_id(_id: Any) -> object {
    if not _id {
        return None;
    }
    parts = _id.split(".");
    if ((len(parts) != 2) or not parts[1]) {
        return None;
    }
    node_details = parts[1].split("_");
    if ((len(node_details) != 2) or not node_details[0]) {
        return None;
    }
    return node_details[0];
}