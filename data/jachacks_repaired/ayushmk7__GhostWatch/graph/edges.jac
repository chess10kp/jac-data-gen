# graph/edges.jac — [SHARED] Pure edge declarations.

edge ImportEdge {
    has is_direct: bool = True;
    has import_type: str = "static";
}

edge BlastEdge {
    has hops: int = 1;
    has impact_type: str = "direct";
}

edge DependencyEdge {
    has scope: str = "direct";
}

edge FindingEdge {
    has confidence: float = 1.0;
    has walker_id: str = "";
}
