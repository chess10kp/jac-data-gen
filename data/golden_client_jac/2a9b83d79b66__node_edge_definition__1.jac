"""Graph-based social network."""

node User {
    has username: str,
        bio: str = "";
}

edge Follows {
    has since: str = "";
}

edge Blocks {
    has reason: str = "";
}

with entry {
    alice = User(username="alice", bio="Developer");
    bob = User(username="bob", bio="Designer");
    carol = User(username="carol", bio="Manager");

    alice +>:Follows(since="2024-01"):+> bob;
    alice +>:Follows(since="2024-03"):+> carol;
    bob +>:Follows(since="2024-02"):+> carol;
}
