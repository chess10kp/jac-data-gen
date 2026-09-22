"""Return a human readable version of the channel type."""
def friendly_channel_type(channel_type: str) -> str {
    match channel_type {
        case "controlled_load":
            return "Controlled Load";
        case "feed_in":
            return "Feed In";
        case _:
            return "General";
    }
}