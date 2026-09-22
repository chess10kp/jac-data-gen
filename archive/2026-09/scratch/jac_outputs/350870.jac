"""
    Create single entry for a switch in topology.json
    """
def formalize_switch(`switch: Any, s: Any) -> object {
    `entry = {
        "mac": ("08:00:00:00:01:" + str(s)),
        "runtime_json": ("./build/" + `switch + "P4runtime.json")
    };
    return `entry;
}