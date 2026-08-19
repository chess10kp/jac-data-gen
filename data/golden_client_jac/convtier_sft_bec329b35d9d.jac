obj LineItem {
    has name: str = "";
    has qty: int = 1;
    has unit: float = 0.0;

    def subtotal -> float {
        return self.qty * self.unit;
    }
}

obj Cart {
    has items: list = [];

    def add(it: LineItem) -> None {
        self.items.append(it);
    }

    def total -> float {
        raw = sum([it.subtotal() for it in self.items]);
        return round(raw * 0.9 if raw >= 100.0 else raw, 2);
    }
}

def cart_total(items: list) -> float {
    cart = Cart();
    for it in items {
        cart.add(LineItem(name=it["name"], qty=it["qty"], unit=it["unit"]));
    }
    return cart.total();
}

with entry {
    print(cart_total([{'name': 'kb', 'qty': 2, 'unit': 45.0}, {'name': 'mouse', 'qty': 1, 'unit': 30.0}]));
}
