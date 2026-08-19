obj Order {
    has id: str;
    has status: str;
    has items: list[dict];
    has customer_email: str;
}

sem Order.status = "Order status: 'pending', 'processing', 'shipped', 'delivered', 'cancelled'";
sem Order.items = "List of items with 'sku', 'quantity', and 'price' fields";
sem Order.customer_email = "Customer's contact email address, e.g. jane@example.com";
