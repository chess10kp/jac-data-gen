node Person { has name: str; }

with entry {
    alice = Person(name="Alice");
    bob = Person(name="Bob");
    secret_node = Person(name="Secret");

    id = jid(alice);
    save(alice);
    printgraph(root);
}
