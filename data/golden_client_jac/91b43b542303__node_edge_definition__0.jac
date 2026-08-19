node Person { has age: int = 0; }
edge Friend { has since: int = 2020; }

walker FilteredWalker {
    can start with Root entry {
        visit [-->];  # Start traversal from root
    }

    can traverse with Person entry {
        # By node type
        visit [-->][?:Person];

        # By edge type
        visit [->:Friend:->];

        # Combined: Friend edges to Person nodes since 2020
        visit [->:Friend:since > 2020:->][?:Person];
    }
}
