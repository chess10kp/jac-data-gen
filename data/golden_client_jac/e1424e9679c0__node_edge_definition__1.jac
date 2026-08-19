node Item {}

with entry {
    a = Item();
    b = Item();

    a ++> b;          # Directed: a → b
    a <++> b;         # Undirected: a ↔ b (creates edges both ways)
}
