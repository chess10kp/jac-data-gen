"""
Verify the contents of a result packet
    - Returns False, list of errors if verification fails
                        OR
    - Returns True, None if passes verification
"""
def _verify_notif_contents(packet: dict[str, object]) -> tuple[bool, list[str] | None] {
    errors: list[str] = [];
    if "id" in packet {
        errors.append("Key 'id' is not allowed in a JSON-RPC notification");
    }
    if "method" not in packet {
        errors.append("method");
    }
    if len(errors) == 0 {
        if not isinstance(packet["method"], str) {
            errors.append("Key 'method' is not required type str");
        }
        if packet.get("params", None) is not None and not isinstance(packet, (dict, list)) {
            errors.append("Key 'params' is not required structured type (list/dict)");
        }
    }
    if len(errors) > 0 {
        return (
            False,
            [
                "Missing required key '{}'".format(err)
                    if len(err.split()) == 1
                    else err for err in errors
            ]
        );
    }
    return (True, None);
}