obj Inventory {
    has stock: dict[str, int] = {};

    def add(item: str, qty: int) -> None {
        self.stock[item] = self.stock.get(item, 0) + qty;
    }

    def total() -> int { return sum(self.stock.values()); }
}

with entry {
    inv = Inventory();
    inv.add("apple", 3);
    inv.add("apple", 2);
    print(inv.total());
}
