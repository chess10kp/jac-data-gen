node Todo { has title: str, done: bool = False; }

with entry {
    root ++> Todo(title="Learn Jac");  # Automatically persisted
}
