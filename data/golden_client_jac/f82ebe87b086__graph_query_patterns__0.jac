node Item {
    has value: int = 0;
}

edge Link {
    has weight: int = 1;
}

walker Visitor {
    can visit with Item entry {
        # All outgoing edges
        neighbors = [-->];

        # All incoming edges
        sources = [<--];

        # Typed outgoing
        linked = [->:Link:->];

        # Filtered by edge attribute
        heavy = [->:Link:weight > 5:->];
    }
}
