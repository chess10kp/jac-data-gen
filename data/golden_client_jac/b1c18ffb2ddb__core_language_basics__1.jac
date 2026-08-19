@subscribe("orders.placed", start_from="earliest")
def replay_all(event: Event) -> None {
    print("replaying", event.id);
}
