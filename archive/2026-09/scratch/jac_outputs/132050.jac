"""Sum grocery list values and return change from cash."""
def checkout(cash: float, list: dict[str, float]) -> float {
    total = float();
    for (key, value) in list.items() {
        total = total + value;
    }
    return cash - total;
}