obj Stack {
    has items: list = [];

    def push(v: int) -> None {
        self.items.append(v);
    }

    def pop_safe -> None {
        if self.items {
            self.items.pop();
        }
    }

    def depth -> int {
        return len(self.items);
    }
}

def stack_depth(ops: list) -> int {
    s = Stack();
    for op in ops {
        if isinstance(op, str) {
            s.pop_safe();
        } else {
            s.push(op);
        }
    }
    return s.depth();
}

with entry {
    print(stack_depth([1, 2, 'pop', 5]));
}
