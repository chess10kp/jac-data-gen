import from jac_scale.events.publisher { publish }
import from jac_scale.events.broker { Event }

walker place_order {
    has order_id: int;
    has amount: float;

    can fire with Root entry {
        publish("orders.placed", Event(
            data={"order_id": self.order_id, "amount": self.amount},
            trace_id="trace-1"
        ));
    }
}
