"""Check order history and return products same as or similar to the given username ordered."""
def check_order_history_product(order_list: list[dict[str, str | int]], username: str) -> set[str | int] {
    category_purchased: set[str] = set();
    product_ids: set[str | int] = set();
    for order in order_list {
        if order['username'] == username {
            category_purchased.add(order['category'] as str);
        }
    }
    for order in order_list {
        if order['category'] in category_purchased {
            product_ids.add(order['product_id']);
        }
    }
    return product_ids;
}