"""Shopping-list walkers plus a targeted single-item remover."""

node ShoppingItem {
    has name: str, quantity: float, unit: str, cost: float, carby: bool;
}

walker GetShoppingList {
    has items: list[ShoppingItem] = [],
        reports: list[list[ShoppingItem]] = [];

    can collect with Root entry { visit [-->]; }

    can gather with ShoppingItem entry {
        self.items.append(here);
    }

    can done with Root exit { report self.items; }
}

walker ClearShoppingList {
    can collect with Root entry { visit [-->]; }

    can clear with ShoppingItem entry {
        del here;
        report {"cleared": True};
    }
}

# New feature: remove a single ingredient by id without clearing the whole list.
walker RemoveShoppingItem {
    has item_id: str,
        reports: list[dict[str, str]] = [];

    can search with Root entry { visit [-->]; }

    can remove with ShoppingItem entry {
        if jid(here) == self.item_id {
            del here;
            report {"removed": self.item_id};
            disengage;
        }
    }
}
