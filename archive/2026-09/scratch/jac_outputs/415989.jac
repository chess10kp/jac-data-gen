"""
Checks whether a port update is being called for a port status change
event.

Port activation events are triggered by our own action: if the only change
in the port dictionary is activation state, we don't want to do any
processing.
"""
def port_status_change(port: dict[str, str], original: dict[str, str]) -> bool {
    port = port.copy();
    original = original.copy();
    port.pop('status');
    original.pop('status');
    return port == original;
}