node Item {
    has name: str;
}

walker:priv CreateItem {
    has name: str,
        reports: list[Item] = [];   # the created Item flows back typed

    can create with Root entry {
        new_item = here ++> Item(name=self.name);
        report new_item[0];  # Report the created item
    }
}

with entry {
    # Usage
    result = root spawn CreateItem(name="New Item");
    created: Item = result.reports[0];  # hydrated as Item on the client
}
