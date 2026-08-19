import json;

# Knowledge base
glob products: list[str] = ["Widget A", "Widget B", "Service X"];
glob prices: dict[str, int] = {"Widget A": 99, "Widget B": 149, "Service X": 29};
glob inventory: dict[str, int] = {"Widget A": 50, "Widget B": 0, "Service X": 999};

"""List all available products."""
def list_products() -> list[str] {
    return products;
}

"""Get the price of a product."""
def get_price(product: str) -> str {
    if product in prices {
        return f"${prices[product]}";
    }
    return "Product not found";
}

"""Check if a product is in stock."""
def check_inventory(product: str) -> str {
    if product in inventory {
        qty = inventory[product];
        if qty > 0 {
            return f"In stock ({qty} available)";
        }
        return "Out of stock";
    }
    return "Product not found";
}

"""Place an order for a product."""
def place_order(product: str, quantity: int) -> str {
    if product not in inventory {
        return "Product not found";
    }
    if inventory[product] < quantity {
        return "Insufficient inventory";
    }
    inventory[product] -= quantity;
    return f"Order placed: {quantity}x {product}";
}

def sales_agent(request: str) -> str by llm(
    tools=[list_products, get_price, check_inventory, place_order]
);

sem sales_agent = "Browse products, check prices and availability, and place orders.";

with entry {
    print("Customer: What products do you have?");
    print(f"Agent: {sales_agent('What products do you have?')}");
    print();

    print("Customer: How much is Widget A and is it in stock?");
    print(f"Agent: {sales_agent('How much is Widget A and is it in stock?')}");
    print();

    print("Customer: I'd like to order 2 Widget A please");
    print(f"Agent: {sales_agent('I want to order 2 Widget A')}");
}
