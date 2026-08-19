node Person { has name: str; }

with entry {
    alice = Person(name="Alice");
    bob = Person(name="Bob");
    secret_node = Person(name="Secret");

    # Attach nodes to root so they are part of the persistent graph
    root ++> alice;
    root ++> bob;
    root ++> secret_node;

    id = jid(alice);
    print(id);
    printgraph(root);
}
