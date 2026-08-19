node Item {}

with entry {
    a = Item();
    b = Item();

    root ++> a;       # Attach the subgraph to root so it is reachable/persisted
    a ++> b;          # Directed: a -> b
}
