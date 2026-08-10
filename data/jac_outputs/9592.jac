"""Add or increment items in inventory using elements from the items list`."""
def add_items(inventory: dict[str, int], items: list[str]) -> dict[str, int] {
    for item in items {
        inventory.setdefault(item, 0);
        inventory[item] += 1;
    }
    return inventory;
}