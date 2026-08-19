node Item {
    has value: int = 0;
}
walker Visitor {
    can visit with Item entry {
        print(here.value);
    }
}
with entry {
    start = Item(value=1);
    root ++> start;
    start spawn Visitor();
}
