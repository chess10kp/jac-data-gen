"""
    Generate pod numbers in sequence
    """
def generate_pod_numbers(n_users: int, n_per_group: int) -> list[int] {
    groups = [];
    for i in range(1, int(n_users / n_per_group) + 2) {
        groups.extend([i] * n_per_group);
    }
    groups = groups[:n_users];
    return groups;
}