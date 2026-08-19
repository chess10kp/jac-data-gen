def:pub remaining_cost -> float {
    total = 0.0;
    for item in [root-->][?:ShoppingItem] { total += item.cost; }
    return total;
}
