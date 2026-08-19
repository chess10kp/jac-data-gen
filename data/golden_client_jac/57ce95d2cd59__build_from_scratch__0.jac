node Item {
    has name: str;
}

walker Finder {
    has target: str;
    has matches: list = [];

    can on_root with Root entry {
        visit [-->];
    }

    can on_item with Item entry {
        if here.name == self.target {
            self.matches.append(here);
            report here;
        }
        visit [-->];
    }
}

with entry {
    root ++> Item(name="foo");
    root ++> Item(name="bar");
    result = root spawn Finder(target="foo");
    print(result.matches);
}
