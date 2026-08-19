node Item {
    has name: str;

    can greet with Finder entry {
        # node side: self = this node, visitor = the arriving walker
        print(f"{self.name} greeted by {visitor.target}");
    }
}

walker Finder {
    has target: str;
    has matches: list = [];

    can on_root with Root entry {
        visit [-->];
    }

    can on_item with Item entry {
        # walker side: self = walker, here = current node
        if here.name == self.target {
            self.matches.append(here);
            report here;                  # emit to result.reports
        }
        visit [-->];
    }
}

with entry {
    root ++> Item(name="foo");
    root ++> Item(name="bar");

    result = root spawn Finder(target="foo");
    print(result.matches);                # [Item(name='foo')]
}
