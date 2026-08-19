import from uuid { uuid4 }

node Person {
    has name: str;
    has id: str = "";       # stable unique identifier for lookup/dedupe

    def postinit() {
        if not self.id {
            self.id = str(uuid4());
        }
    }
}

edge Friend {
    has since: str = "";    # when the friendship was formed
}

with entry {
    alice = Person(name="Alice");
    bob = Person(name="Bob");
    alice +>: Friend(since="2026-01") :+> bob;
    print(f"{alice.name} ({alice.id}) -> {bob.name} ({bob.id})");
}
