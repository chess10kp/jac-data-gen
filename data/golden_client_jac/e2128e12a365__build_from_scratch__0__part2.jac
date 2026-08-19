obj User {
    has name: str;                      # required - REQUIRED fields come first
    has age: int = 0;                   # defaulted fields come AFTER all required ones
    has tags: list[str] = [];           # typed list
    has meta: dict[str, str] = {};      # typed dict
    has manager: User | None = None;    # optional reference
}

with entry {
    alice = User(name="alice");
    bob   = User(name="bob", age=30);
    alice.tags.append("admin");
    print(alice.name, alice.age, alice.tags);
}
