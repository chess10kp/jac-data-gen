obj User {
    has name: str;                       # required - must be passed at construction
    has age: int = 0;                    # typed primitive with default
    has tags: list[str] = [];            # generic container
    has meta: dict[str, int] = {};       # two-type-param generic
    has manager: User | None = None;     # self-referencing optional
}


def score(points: list[int]) -> int {
    total = sum(points);                 # inferred int, no annotation needed
    return total;
}


def greet(u: User) -> str {
    if u.manager is None {
        return "Hi " + u.name + ", no manager";
    }
    return "Hi " + u.name + ", manager is " + u.manager.name;  # safe - None branch returned
}


def describe(x: int | str) -> str {      # union type: x is either int or str
    if isinstance(x, int) {
        return "number: " + str(x);
    }
    return "text: " + x;                 # narrowed to str by the isinstance check
}


def log_any(value: any) {                # any = the gradual type; no import needed
    print(value);
}


with entry {
    alice = User(name="alice", age=30);
    bob   = User(name="bob", manager=alice);

    print(score([1, 2, 3]));             # 6
    print(greet(bob));                   # Hi bob, manager is alice
    print(describe(42));                 # number: 42
    print(describe("hi"));               # text: hi
    log_any({"foo": "bar"});             # {'foo': 'bar'}
}
