node Item {
    has value: int = 0;
}
edge Link {
    has weight: int = 1;
}
walker Visitor {
    can visit with Item entry {
        heavy = [->:Link:weight > 5:->];
        for n in heavy {
            print(n.value);
        }
        visit [-->];
    }
}
