obj User {
    has name: str;
    has age: int = 0;
    has tags: list[str] = [];
    has meta: dict[str, str] = {};
    has manager: User | None = None;
}

with entry {
    alice = User(name="alice");
    print(alice.name, alice.age, alice.tags);
}
