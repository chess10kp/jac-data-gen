walker Reader {}
walker Writer { has new_value: int = 0; }

node DataNode {
    has value: int = 0;

    # Anonymous ability fires for every walker that visits this node
    can handle with entry {
        print(f"Visited by {type(visitor).__name__}, value={self.value}");
    }
}
