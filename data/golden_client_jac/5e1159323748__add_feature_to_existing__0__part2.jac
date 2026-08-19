import from byllm.lib { Model }

glob llm = Model(model_name="gpt-4o");

glob kb: dict = {
    "products": ["Widget A", "Widget B", "Service X"],
    "prices": {"Widget A": 99, "Widget B": 149, "Service X": 29},
    "inventory": {"Widget A": 50, "Widget B": 0, "Service X": 999},
    "descriptions": {
        "Widget A": "Our flagship widget",
        "Widget B": "Budget-friendly widget",
        "Service X": "Monthly support service"
    }
};

"""List all available products."""
def list_products() -> list[str] {
    return [str(p) for p in kb["products"]];
}

"""Get the price of a product."""
def get_price(product: str) -> str {
    if product in kb["prices"] {
        return f"${kb['prices'][product]}";
    }
    return "Product not found";
}

"""Check if a product is in stock."""
def check_inventory(product: str) -> str {
    qty = kb["inventory"].get(product, 0);
    return f"In stock ({qty} available)" if qty > 0 else "Out of stock";
}

"""Get a product description."""
def get_description(product: str) -> str {
    return str(kb["descriptions"].get(product, "No description available"));
}

def sales_agent(request: str) -> str by llm(
    tools=[list_products, get_price, check_inventory, get_description]
);
sem sales_agent = "Help customers browse products, check prices and availability.";
