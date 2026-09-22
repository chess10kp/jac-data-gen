"""Get the name for a cluster's auto scaling group."""
def get_auto_scaling_group_name(cluster: str) -> str {
    return str(cluster) + "--ecs-cluster-auto-scaling-group";
}