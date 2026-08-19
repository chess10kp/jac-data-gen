node Person { has name: str; }
edge Friend {}

node Todo {
    has completed: bool = False;
}

with entry {
    alice = Person(name="Alice");
    bob = Person(name="Bob");
    alice +>: Friend :+> bob;

    # Delete specific edge
    alice del --> bob;

    # Delete node
    del bob;
}

# Delete current node from within a walker
walker Cleanup {
    can check with Todo entry {
        if here.completed {
            node_id = jid(here);
            del here;
            report {"deleted": node_id};
        }
    }
}
