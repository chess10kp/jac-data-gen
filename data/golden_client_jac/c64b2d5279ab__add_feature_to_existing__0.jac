walker RemoveShoppingItem {
    has item_id: str;
    can remove with ShoppingItem entry {
        if jid(here) == self.item_id { del here; }
    }
}
