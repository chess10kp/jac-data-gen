obj Invoice {
    has amount: int;
    has tax_rate: float = 0.1;
}

def total(inv: Invoice) -> int {
    return inv.amount;
}

def total_with_tax(inv: Invoice) -> float {
    return inv.amount * (1.0 + inv.tax_rate);
}

with entry {
    inv = Invoice(amount=100);
    print(total(inv));
    print(total_with_tax(inv));
}
