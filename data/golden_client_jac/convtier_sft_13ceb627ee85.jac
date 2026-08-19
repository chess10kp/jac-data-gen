obj Invoice {
    has prices: dict = {};
    has qty: dict = {};

    def total -> int {
        t = 0;
        for (sku, n) in self.qty.items() {
            t += self.prices.get(sku, 0) * n;
        }
        return t;
    }
}

def invoice_total(order: dict) -> int {
    return Invoice(prices=order["prices"], qty=order["qty"]).total();
}

with entry {
    print(invoice_total({'prices': {'pen': 3, 'pad': 7}, 'qty': {'pen': 4, 'pad': 2}}));
}
