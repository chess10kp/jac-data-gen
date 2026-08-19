def total_with_tax(inv: Invoice) -> float {
    return inv.amount * (1.0 + inv.tax_rate);
}
