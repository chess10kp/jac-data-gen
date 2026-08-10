"""Returns the service name from the pod name."""
def get_service_name(pod_name: str) -> str {
    pod_name[:-6]
}