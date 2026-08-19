node Item {}

walker Visitor {
    can start with Root entry {
        # Bootstrap: without a Root ability, a walker spawned at root never
        # reaches any Item, so `traverse` below would never fire.
        visit [-->];
    }

    can traverse with Item entry {
        visit [-->] else {              # Fallback if no nodes to visit
            print("No outgoing edges");
        }
    }
}

with entry {
    root ++> Item();
    root spawn Visitor();
}
