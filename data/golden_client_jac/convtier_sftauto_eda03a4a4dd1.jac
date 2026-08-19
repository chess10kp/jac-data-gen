def get_average_price(data: Any) -> object {
    if not data {
        return 0;
    }
    total_price = sum(item["price"] for item in data);
    average_price = total_price / len(data);
    return round(average_price);
}



with entry {
    print(get_average_price(0));
}
