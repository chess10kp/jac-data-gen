"""Extract network information for a docker container."""
def __extract_network_from_docker_container(docker_container: Any) -> object {
    network_bindings = docker_container.get("networkBindings");
    bindings = [];
    if network_bindings {
        bindings = [
            (
                network["bindIP"]
                + " ("
                + str(network["hostPort"])
                + "[host] -> "
                + str(network["containerPort"])
                + "[network])"
            ) for network in network_bindings
        ];
    }
    if (bindings is []) {
        bindings = "no network binding";
    } else {
        bindings = ", ".join(bindings);
    }
    return (docker_container["name"] + " -> " + bindings);
}