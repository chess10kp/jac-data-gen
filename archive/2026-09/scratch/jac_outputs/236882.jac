"""
    Transform a integer globus status to
    either Wait, Idle, Running, Held, Completed or Removed
    """
def interpretStatus(status: int, default_status: str = "Idle") -> str {
    match status {
        case 5:
            return "Completed";
        case 9:
            return "Removed";
        case 1:
            return "Running";
        case 12:
            return "Held";
        case 0:
            return "Wait";
        case 17:
            return "Idle";
        case _:
            return default_status;
    }
}