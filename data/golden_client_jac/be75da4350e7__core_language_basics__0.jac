import from jac_scale.events.broker { EventStreamBroker }

def drain(broker: EventStreamBroker) -> int {
    batch = broker.consume(
        "orders.placed", max_messages=10, timeout_seconds=2.0
    );
    for ev in batch {
        # ... process ev ...
        broker.ack(ev);
    }
    return len(batch);
}
