import from byllm.lib { Image }

obj LineItem {
    has description: str;
    has quantity: int;
    has price: float;
}

obj Receipt {
    has store_name: str;
    has date: str;
    has items: list[LineItem];
    has total: float;
}

"""Extract all information from this receipt image."""
def parse_receipt(img: Image) -> Receipt by llm();

# Reconcile the extracted line items against the stated total.
def verify_receipt(receipt: Receipt) -> bool {
    computed = 0.0;
    for item in receipt.items {
        computed += item.price * item.quantity;   # quantity actually used
    }
    return abs(computed - receipt.total) <= 0.01;
}
