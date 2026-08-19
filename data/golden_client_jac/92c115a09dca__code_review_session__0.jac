node Item { has value: int = 0; }

walker Example {
    has budget: int = 10;

    can start with Root entry { visit [-->]; }

    can collect with Item entry {
        report here.value;
        if here.value > self.budget {
            disengage;   # stops the whole walker, not just this ability
        }
        visit [-->];
    }
}

with entry {
    root ++> Item(value=3) ++> Item(value=20) ++> Item(value=5);
    result = root spawn Example();
    print(result.reports);
}
