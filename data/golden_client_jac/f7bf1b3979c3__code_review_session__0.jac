node Item { has name: str = ""; }

walker Example {
    can start with Root entry {
        visit [-->];
    }

    can traverse with Item entry {
        print(f"Visiting {here.name}");
        visit [-->];
        print("This runs before the queued children are visited");
    }
}

with entry {
    root ++> Item(name="a") ++> Item(name="b");
    root spawn Example();
}
