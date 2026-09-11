"""Guard: rajat-wyrm/InternOps#1755."""
obj TeamStore { has manager_of: dict[str, str] = {}; has depth_cap: int = 100; }
node User { has uid: str; }
edge Manages {}
walker TeamWalk {
    has claimed: dict[str, bool] = {}; has reached: list[str] = []; has depth: int = 0; has cap: int = 100; has origin: str = "";
    can step with User entry {
        if here.uid in self.claimed { skip; }
        if self.depth >= self.cap { skip; }
        self.claimed[here.uid] = True;
        if here.uid != self.origin { self.reached.append(here.uid); }
        self.depth += 1;
        visit [->:Manages:->] else { disengage; };
    }
}
def _find(uid: str) -> User | None { for n in [-->][?:User] { if n.uid == uid { return n; } } return None; }
def load_team(manager_of: dict[str, str], depth_cap: int = 100) -> TeamStore {
    mp: dict[str, User] = {}; ids: set[str] = set();
    for (u, m) in manager_of.items() { ids.add(u); ids.add(m); }
    for uid in ids { fresh = User(uid=uid); root ++> fresh; mp[uid] = fresh; }
    for (u, m) in manager_of.items() { child = mp.get(u, None); boss = mp.get(m, None); if child is not None and boss is not None { boss +>:Manages():+> child; } }
    return TeamStore(manager_of=manager_of, depth_cap=depth_cap);
}
def team_members(g: TeamStore, manager_id: str) -> list[str] {
    anchor = _find(manager_id); if anchor is None { return []; }
    w = anchor spawn TeamWalk(claimed={}, reached=[], depth=0, cap=g.depth_cap, origin=manager_id);
    return sorted(w.reached);
}
def would_cycle(g: TeamStore, user_id: str, new_manager: str) -> bool { if user_id == new_manager { return True; } return new_manager in team_members(g, user_id); }

test "depth cap on manager cycle" {
    g = load_team({"a": "b", "b": "a"}, depth_cap=5);
    assert team_members(g, "a") == ["b"];
}
test "transitive team closure" {
    g = load_team({"a": "boss", "b": "a", "c": "b"});
    assert team_members(g, "boss") == ["a", "b", "c"];
}
test "would cycle detects descendant manager" {
    g = load_team({"a": "boss", "b": "a"});
    assert would_cycle(g, "a", "b");
}
