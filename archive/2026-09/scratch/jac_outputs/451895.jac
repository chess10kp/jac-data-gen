glob ASCII_UPPERCASE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';

"""Assign a cluster label (A–Z, AA, AB, …) from a cluster id."""
def get_cluster_label(cluster_id: int) -> str {
    cluster_label = '';
    current_index = cluster_id;
    while current_index >= 0 {
        if current_index < len(ASCII_UPPERCASE) {
            cluster_label += ASCII_UPPERCASE[current_index];
        } else {
            for letter in reversed(cluster_label) {
                if letter != 'Z' {
                    idx = ASCII_UPPERCASE.index(cluster_label[-1]);
                    cluster_label = cluster_label[:-1] + ASCII_UPPERCASE[idx + 1];
                    break;
                }
            } else {
                cluster_label = 'A' + cluster_label;
            }
        }
        current_index -= 26;
    }
    return cluster_label;
}