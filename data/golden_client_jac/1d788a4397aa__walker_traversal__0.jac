node Item {}

walker Visitor {
    can traverse with Item entry {
        visit [-->] else {              # Fallback if no nodes to visit
            print("No outgoing edges");
        }
    }
}
