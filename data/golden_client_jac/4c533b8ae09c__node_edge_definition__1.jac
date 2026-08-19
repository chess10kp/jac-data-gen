node Item {
    has data: str;
}

walker:priv ListItems {
    has reports: list[list[str]];
    has items: list[str] = [];

    can collect with Root entry {
        visit [-->];
    }

    can gather with Item entry {
        self.items.append(here.data);
    }

    can finish with Root exit {
        report self.items;  # Single report with all data (type-checked)
    }
}

with entry {
    # Usage
    result = root spawn ListItems();
    items = result.reports[0];  # The complete list
}
