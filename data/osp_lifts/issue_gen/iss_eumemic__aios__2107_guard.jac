"""
Subtree authority: authorize actor to act on target when target is self or a descendant.
Synthetic lift for eumemic/aios#2107.
"""

node Account {
    has cid: str;
    has archived: bool = False;
}

edge Parent {}

node RegistryRoot {}

walker Finder {
    has target_id: str;
    has claimed: dict[str, bool] = {};
    has found: object = None;

    can seek_root with RegistryRoot entry {
        print("finder: registry entry");
        kids: list[Account] = [];
        for ch in [here ->:Parent:->][?:Account] {
            kids.append(ch);
        }
        if kids {
            visit kids;
        } else {
            disengage;
        }
    }

    can seek with Account entry {
        if here.cid == self.target_id {
            self.found = here;
            print(f"finder: located {here.cid}");
            disengage;
        }
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        kids: list[Account] = [];
        for ch in [here ->:Parent:->][?:Account] {
            kids.append(ch);
        }
        if kids {
            visit kids;
        } else {
            disengage;
        }
    }
}

walker DescendantProbe {
    has target_id: str;
    has claimed: dict[str, bool] = {};
    has hit: bool = False;

    can step with Account entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        if here.cid == self.target_id {
            self.hit = True;
            print(f"descendant_probe: hit {here.cid}");
            disengage;
        }
        kids: list[Account] = [];
        for ch in [here ->:Parent:->][?:Account] {
            if not ch.archived {
                kids.append(ch);
            }
        }
        visit :0: kids;
    }
}

walker SubtreeCollect {
    has claimed: dict[str, bool] = {};
    has ids: list[str] = [];

    can step with Account entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        if not here.archived {
            self.ids.append(here.cid);
        }
        kids: list[Account] = [];
        for ch in [here ->:Parent:->][?:Account] {
            kids.append(ch);
        }
        visit :0: kids;
    }
}

def find_account(registry: RegistryRoot, account_id: str) -> object {
    w = registry spawn Finder(target_id=account_id, claimed={}, found=None);
    print(f"find_account: {account_id}");
    return w.found;
}

def is_descendant_of(actor: Account, target_id: str) -> bool {
    w = actor spawn DescendantProbe(target_id=target_id, claimed={}, hit=False);
    print(f"is_descendant_of: {actor.cid} -> {target_id} => {w.hit}");
    return w.hit;
}

def build_registry(entries: list[list]) -> RegistryRoot {
    reg = RegistryRoot();
    by_id: dict[str, Account] = {};
    for row in entries {
        aid: str = row[0];
        if aid not in by_id {
            arch: bool = False;
            if len(row) > 2 {
                arch = row[2];
            }
            by_id[aid] = Account(cid=aid, archived=arch);
        }
    }
    for row in entries {
        aid: str = row[0];
        pid: str = "";
        if len(row) > 1 {
            pid = row[1];
        }
        nd = by_id[aid];
        if pid == "" {
            reg ++> nd;
        } else if pid in by_id {
            par: Account = by_id[pid] as Account;
            par +>:Parent:+> nd;
        } else {
            reg ++> nd;
        }
    }
    return reg;
}

def can_act_as(registry: RegistryRoot, actor_id: str, target_id: str) -> bool {
    actor = find_account(registry, actor_id);
    target = find_account(registry, target_id);
    if actor is None or target is None {
        return False;
    }
    if actor.archived or target.archived {
        return False;
    }
    if actor_id == target_id {
        return True;
    }
    return is_descendant_of(actor, target_id);
}

def resolve_target_account(
    registry: RegistryRoot, actor_id: str, selector: str | None
) -> str {
    chosen: str = actor_id;
    if selector is not None {
        chosen = selector;
    }
    if not can_act_as(registry, actor_id, chosen) {
        return "";
    }
    return chosen;
}

def impersonation_audit_pair(actor_id: str, target_id: str) -> list[str] {
    pair: list[str] = [];
    pair.append(actor_id);
    pair.append(target_id);
    return pair;
}

def list_subtree_account_ids(registry: RegistryRoot, actor_id: str) -> list[str] {
    actor = find_account(registry, actor_id);
    if actor is None {
        return [];
    }
    w = actor spawn SubtreeCollect(claimed={}, ids=[]);
    print(f"list_subtree_account_ids: {actor_id}");
    return sorted(w.ids);
}

test "self_authorization" {
    rows: list[list] = [["a", ""]];
    reg = build_registry(rows);
    assert can_act_as(reg, "a", "a");
}

test "parent_acts_on_descendant" {
    rows: list[list] = [["p", ""], ["c", "p"]];
    reg = build_registry(rows);
    assert can_act_as(reg, "p", "c");
}

test "sibling_denied" {
    rows: list[list] = [["p", ""], ["c1", "p"], ["c2", "p"]];
    reg = build_registry(rows);
    assert not can_act_as(reg, "c1", "c2");
}

test "archived_actor_denied" {
    rows: list[list] = [["a", "", True], ["b", "a"]];
    reg = build_registry(rows);
    assert not can_act_as(reg, "a", "b");
}

test "list_subtree_sorted_excludes_archived" {
    rows: list[list] = [["r", ""], ["b", "r"], ["a", "r", True], ["c", "b"]];
    reg = build_registry(rows);
    got = list_subtree_account_ids(reg, "r");
    assert got == ["b", "c", "r"];
}

test "resolve_target_unauthorized_empty" {
    rows: list[list] = [["p", ""], ["c1", "p"], ["c2", "p"]];
    reg = build_registry(rows);
    assert resolve_target_account(reg, "c1", "c2") == "";
}
