"""Create a BIG-IP Network configuration from the Kubernetes config."""
def create_network_config_kubernetes(config: dict[str, object]) -> dict[str, object] {
    f5_network: dict[str, object] = {};
    if 'openshift-sdn' in config {
        openshift_sdn = config['openshift-sdn'];
        f5_network['fdb'] = openshift_sdn;
    }
    return f5_network;
}