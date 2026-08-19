obj LinkedNode {
    has value: int = 0,
        next: LinkedNode | None = None;

    static def create(v: int) -> LinkedNode {
        return LinkedNode(value=v);
    }

    # New: count the length of the chain from this node
    def length() -> int {
        count = 1;
        cur = self.next;
        while cur is not None {
            count += 1;
            cur = cur.next;
        }
        return count;
    }
}

with entry {
    a = LinkedNode.create(1);
    a.next = LinkedNode.create(2);
    a.next.next = LinkedNode.create(3);
    print(a.length());
}
