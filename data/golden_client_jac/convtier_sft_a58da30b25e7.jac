def _subtotal(prices: list) -> float {
    total = 0.0;
    for p in prices {
        total += p;
    }
    return total;
}

def _with_tax(amount: float, rate: float) -> float {
    return amount * (1.0 + rate);
}

def receipt_total(order: dict) -> str {
    opts = {"tax_rate": 0.1, "coupon": 0.0};
    opts.update(order);
    net = _subtotal(opts["prices"]) - opts["coupon"];
    return f"due: {_with_tax(net, opts['tax_rate']):.2f}";
}

with entry {
    print(receipt_total({'prices': [10.0, 5.0]}));
}
