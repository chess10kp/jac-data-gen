"""Club ladder: Player nodes on root, rank 1 is the top."""

node Player {
    has name: str;
    has rank: int;
}

"""Add a player at the bottom of the ladder."""
def join(name: str) -> Player {
    n = len([root -->[?:Player]]);
    return root ++> Player(name=name, rank=n + 1);
}

def player(name: str) -> Player | None {
    for p in [root -->[?:Player]] {
        if p.name == name {
            return p;
        }
    }
    return None;
}
