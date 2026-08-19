node Todo { has title: str, done: bool = False; }

with entry {
    existing = [root -->][?:Todo];
    if not existing {
        root ++> Todo(title="Learn Jac");  # seed once, idempotently
    }
}
