import from http { HTTPMethod }

@restspec(method=HTTPMethod.GET, path="/items/{item_id}")
walker :pub get_item {
    has item_id: str;
    can fetch with Root entry { report {"item_id": self.item_id}; }
}

@restspec(method=HTTPMethod.GET, path="/users/{user_id}/orders")
walker :pub get_user_orders {
    has user_id: str;          # Path parameter
    has status: str = "all";   # Query parameter
    can fetch with Root entry { report {"user_id": self.user_id, "status": self.status}; }
}
