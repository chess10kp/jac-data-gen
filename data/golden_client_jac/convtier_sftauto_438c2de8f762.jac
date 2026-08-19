def calculate_tax(price: Any) -> object {
    tax_rate = 0.2;
    total = price + (price * tax_rate);
    if (price > 1000) {
        discount = price * 0.1;
        total -= discount;
    }
    total = round(total, 2);
    return total;
}



with entry {
    print(calculate_tax(5));
    print(calculate_tax(10));
    print(calculate_tax(2));
}
