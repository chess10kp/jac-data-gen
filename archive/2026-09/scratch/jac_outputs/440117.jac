"""Returns the service name from a service:action combination."""
def get_service_from_action(action: str) -> str {
    (service, action_name) = action.split(':');
    return service.lower();
}