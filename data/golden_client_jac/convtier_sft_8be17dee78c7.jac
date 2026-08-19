walker Shopper { has wallet: int; has bought: int = 0; }

node Item {
    has price: int;
    can sell with Shopper entry {
        if visitor.wallet >= self.price {
            visitor.wallet -= self.price;
            visitor.bought += 1;
            visit [-->];
        }
    }
}

walker Sale {
    has cap: int;
    has off: int;
    can tag with Item entry {
        if here.price > self.cap { here.price -= self.off; }
        visit [-->];
    }
}

def sale_purchases(spec: dict) -> int {
    prices: list = list(spec["prices"]);
    if not prices { return 0; }
    items: list = [Item(price=int(v)) for v in prices];
    for (a, b) in zip(items, items[1:]) { a ++> b; }
    sale = items[0] spawn Sale(cap=int(spec["cap"]), off=int(spec["off"]));
    return (items[0] spawn Shopper(wallet=int(spec["budget"]))).bought;
}

with entry {
    print(sale_purchases({'prices': [6, 4, 8], 'cap': 5, 'off': 3, 'budget': 10}));
}
