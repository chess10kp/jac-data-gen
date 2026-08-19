obj User {
    has name: str;
    has age: int = 0;
    has tags: list[str] = [];
    has meta: dict[str, int] = {};
    has manager: User | None = None;
}

def score(points: list[int]) -> int {
    total = sum(points);
    return total;
}

def greet(u: User) -> str {
    if u.manager is None {
        return "Hi " + u.name + ", no manager";
    }
    return "Hi " + u.name + ", manager is " + u.manager.name;
}

with entry {
    alice = User(name="alice", age=30);
    bob   = User(name="bob", manager=alice);
    print(score([1, 2, 3]));
    print(greet(bob));
}
