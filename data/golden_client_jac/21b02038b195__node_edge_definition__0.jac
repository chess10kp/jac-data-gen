node Person {}
edge EdgeType {}
edge Edge { has attr: int = 0; has a: int = 0; has b: int = 0; }
edge Friend {}

walker Traverser {
    can query with Person entry {
        # Basic forms
        outgoing = [-->];                     # All outgoing nodes
        incoming = [<--];                     # All incoming nodes
        both = [<-->];                        # Both directions

        # Typed forms
        via_type = [->:EdgeType:->];          # Outgoing via EdgeType

        # With conditions
        filtered = [->:Edge:attr > 0:->];     # Filter by edge attribute

        # Node type filter
        people = [-->][?:Person];             # Filter result nodes by type

        # Get edges vs nodes
        edges = [edge -->];                   # Get edge objects
        friends = [edge ->:Friend:->];        # Typed edge objects
    }
}
