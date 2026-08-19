walker Reader {}
walker Writer { has new_value: int = 0; }

node DataNode {
    has value: int = 0;

    # Fires for every walker that visits this node
    can handle with entry {
        print(f"Visited by {type(visitor).__name__}, value={self.value}");
    }
}

with entry {
    # Build a node and actually run the walkers so `handle` fires
    d = root ++> DataNode(value=42);
    d[0] spawn Reader();
    d[0] spawn Writer(new_value=7);
}
