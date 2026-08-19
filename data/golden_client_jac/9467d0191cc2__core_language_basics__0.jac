import from jac_scale.events.subscriber { subscribe }
import from jac_scale.events.broker { Event }

@subscribe("orders.placed")
def on_order_placed(event: Event) -> None {
    print(event.event_type, event.data);
}
