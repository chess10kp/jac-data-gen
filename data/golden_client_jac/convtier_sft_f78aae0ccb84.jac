obj UserView {
    has id: str;
    has name: str;
}

def to_follow(feed: dict) -> list {
    users = [UserView(id=p["id"], name=p["name"]) for p in feed["profiles"]];
    blocked = feed["following"] + [feed["me"]];
    return [u.name for u in users if u.id not in blocked];
}

with entry {
    print(to_follow({'profiles': [{'id': 'u1', 'name': 'ada'}, {'id': 'u2', 'name': 'grace'}, {'id': 'u3', 'name': 'linus'}], 'following': ['u2'], 'me': 'u1'}));
}
