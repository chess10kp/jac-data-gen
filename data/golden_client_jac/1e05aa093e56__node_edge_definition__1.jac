obj LinkedNode {
    has value: int = 0,
        next: LinkedNode | None = None;

    static def create(v: int) -> LinkedNode {
        return LinkedNode(value=v);
    }
}
