import from math { sqrt }
import os;

glob LIMIT: int = 5;

enum Color {
    RED = 1,
    GREEN = 2
}

obj Empty {}

obj Card(Base) {
    has label: str = "a",
        value: int = 0;

    def show() -> str {
        return self.label;
    }

    def todo() -> int;
}

impl Card.todo() -> int {
    return 1;
}

def add_two(x: int, y: int) -> int {
    z = x + y;
    return z;
}

def stub() {}

with entry {
    print("é" + add_two(1, 2));
}

test "adds" {
    assert add_two(1, 1) == 2;
}
