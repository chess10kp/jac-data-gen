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
