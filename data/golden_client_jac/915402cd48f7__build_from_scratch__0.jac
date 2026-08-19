node Item {
    has name: str;
}

walker:priv CreateItem {
    has name: str;

    can create with Root entry {
        new_item = here ++> Item(name=self.name);
        report new_item[0];
    }
}

with entry {
    result = root spawn CreateItem(name="New Item");
}
