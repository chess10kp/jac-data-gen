node Item {}

walker Visitor {
    can go with Item entry {
        visit [-->];                    # Visit all outgoing nodes
        visit [<--];                    # Visit all incoming nodes
        visit [<-->];                   # Visit both directions
    }
}
