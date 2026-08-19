import from http { HTTPMethod }

node Order {
    has order_id: str,
        status: str = "pending";
}

@restspec(method=HTTPMethod.GET, path="/items/{item_id}")
walker :pub get_item {
    has item_id: str;
    can fetch with Root entry {
        report {"item_id": self.item_id};
    }
}

# Private: JWT-authenticated, per-user isolated. No user_id in the URL --
# the runtime resolves the caller's own root, so one user can never read
# another's orders.
@restspec(method=HTTPMethod.GET, path="/orders")
walker :priv get_user_orders {
    has status: str = "all";

    can fetch with Root entry {
        orders = [o for o in [-->][?:Order] if self.status == "all" or o.status == self.status];
        report {"status": self.status, "orders": [o.order_id for o in orders]};
    }
}
