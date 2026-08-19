obj Stack {
    has items: list[int] = [];

    def push(x: int) -> None { self.items.append(x); }

    def peek() -> int { return self.items[-1]; }

    def size() -> int { return len(self.items); }
}

with entry {
    s = Stack();
    s.push(1);
    s.push(2);
    s.push(3);
    print(s.peek());
    print(s.size());
}
