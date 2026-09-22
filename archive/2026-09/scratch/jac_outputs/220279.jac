"""Check if prop and value is valid."""
def validate_message_prop_value(prop: str, value: str) -> bool {
    if prop not in ("Direction", "Speed", "Status") {
        return False;
    }
    match prop {
        case "Direction":
            return value in ("E", "W", "N", "S");
        case "Speed":
            return value.isdigit();
        case "Status":
            return value in ("Off", "Active");
        case _:
            return False;
    }
}