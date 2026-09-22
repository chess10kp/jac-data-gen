"""Generate action in imagebuilder components."""
def _generate_action(action_name: Any, commands: Any) -> object {
    action = {
        "name": action_name,
        "action": "ExecuteBash",
        "inputs": {"commands": [commands]}
    };
    return action;
}