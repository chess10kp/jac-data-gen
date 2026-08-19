obj Queue {
    has items: list[int] = [];

    def enqueue(x: int) -> None { self.items.append(x); }

    def dequeue() -> int { return self.items.pop(0); }

    def size() -> int { return len(self.items); }
}

with entry {
    q = Queue();
    q.enqueue(1); q.enqueue(2); q.enqueue(3);
    print(q.dequeue());
    print(q.size());
}
