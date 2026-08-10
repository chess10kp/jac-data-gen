"""Check if an event is relevant and returns the inner event dict if it is"""
def relevant_event(event: dict[str, object]) -> dict[str, object] | None {
    if "event" in event.keys() {
        e = event["event"] as dict[str, object];
        if e["type"] == "message" {
            return e;
        }
    }
    return None;
}