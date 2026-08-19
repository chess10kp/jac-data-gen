node Item {
    has data: str;
}

# Bad: Creates many small reports
walker:priv BadPattern {
    can process with Item entry {
        report here.data;  # N reports for N items
    }
}

# Good: Accumulate and report once
walker:priv GoodPattern {
    has items: list = [];

    can start with Root entry {
        visit [-->];
    }

    can process with Item entry {
        self.items.append(here.data);
    }

    can finish with Root exit {
        report self.items;  # One report with all items
    }
}
