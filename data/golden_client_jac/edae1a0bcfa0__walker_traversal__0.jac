walker ListItems {
    has items: list = [];

    # 'can' ability -- fires automatically when walker enters a Root node
    can collect with Root entry {
        visit [-->];
    }

    # 'can' ability -- fires on each Item node visited
    can gather with Item entry {
        self.items.append(here.value);
    }

    # 'can' ability -- fires when walker exits Root
    can report_all with Root exit {
        report self.items;
    }
}
