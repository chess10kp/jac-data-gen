def calculate_total_price(data: Any) -> object {
    total_price = 0;
    for item in data {
        total_price += item["price"];
    }
    return total_price;
}



with entry {
    print(calculate_total_price([]));
}
