"""Guard for rec_25_subscription_cascade -- candidate OSP lift inlined
verbatim (same-prefix sibling imports are unreliable across jac's native
seam), plus behavioral tests: plan + exclusive add-on cancellation, shared
bundle surviving then dying with its last holder via the orphan sweep,
deep chains, unknown-id tolerance, idempotent re-unsubscribe.
"""


node Subscription {
    has sub_id: str;
    has plan_name: str;
    has is_root: bool = False;
    has holders: int = 0;   # live parent subscriptions pointing here
}

edge Owns { }

"""Collect the cancellation closure below one subscription."""
walker CancelScan {
    has doomed: list[Subscription] = [];
    has seen: dict[str, bool] = {};

    can scan with Subscription entry {
        if here.sub_id in self.seen {
            skip;           # diamond revisit / cycle policy: collect once,
        }                   # but keep sibling branches alive (no disengage)
        self.seen[here.sub_id] = True;
        self.doomed.append(here);
        visit [->:Owns:->];
    }
}

obj SubscriptionRegistry {
    has subs: dict[str, Subscription];

    def register(sub_id: str, plan_name: str, is_root: bool = False)
            -> Subscription {
        fresh = Subscription(sub_id=sub_id, plan_name=plan_name,
                             is_root=is_root);
        self.subs[sub_id] = fresh;
        return fresh;
    }

    """Make *child_id* an add-on of *parent_id*; unknown refs refused."""
    def attach(parent_id: str, child_id: str) -> bool {
        parent = self.subs.get(parent_id);
        child = self.subs.get(child_id);
        if child is None or parent is None {
            return False;
        }
        parent +>:Owns:+> child;
        child.holders += 1;
        return True;
    }

    """Cancel *sub_id* plus descendants; sweeps orphans afterwards.

    Returns every removed id sorted. Unknown ids report [].
    """
    def unsubscribe(sub_id: str) -> list[str] {
        # Phase COLLECT -- decide nothing destructively inside the walk.
        start = self.subs.get(sub_id);
        if start is None {
            return [];
        }
        scan = start spawn CancelScan();
        doomed = scan.doomed;

        # Phase APPLY -- mutation strictly after the walk finished.
        for dead in doomed {
            kids = [dead ->:Owns:->] as list[Subscription];
            for child in kids {
                child.holders -= 1;         # dying parent releases its hold
                dead del ->:Owns:-> child;
            }
        }
        removed: list[str] = [];
        for dead in doomed {
            # the requested id always dies; others need no surviving holder
            if dead.sub_id == sub_id or dead.is_root or dead.holders <= 0 {
                _gone = self.subs.pop(dead.sub_id, None);
                removed.append(dead.sub_id);
            }
        }
        for victim in doomed {
            if victim.sub_id in self.subs and self.subs[victim.sub_id] is victim {
                continue;       # spared shared bundle stays registered
            }
            del victim;
        }
        # orphan sweep: no live holder left and not a top-level plan
        orphans: list[str] = [];
        for sid in self.subs.keys() {
            cand = self.subs[sid];
            if cand.holders <= 0 and not cand.is_root {
                orphans.append(sid);
            }
        }
        for sid in orphans {
            victim = self.subs[sid];
            del victim;
            _gone = self.subs.pop(sid, None);
            removed.append(sid);
        }
        return sorted(removed);
    }

    def active -> list[str] {
        return sorted(self.subs.keys());
    }

    def is_active(sub_id: str) -> bool {
        return sub_id in self.subs;
    }
}

"""Build a fresh deterministic registry; creation order = fixture order."""
def load_graph(spec: list[tuple[str, str, bool]],
               links: list[tuple[str, str]]) -> SubscriptionRegistry {
    reg = SubscriptionRegistry(subs={});
    for row in spec {
        _made = reg.register(row[0], row[1], row[2]);
    }
    for pair in links {
        _ok = reg.attach(pair[0], pair[1]);
    }
    return reg;
}

test "cancels_plan_and_exclusive_addons" {
    reg = load_graph(
        spec=[("plan_pro", "Pro", True), ("plan_basic", "Basic", True),
              ("adfree", "Ad-free", False), ("bundle", "Bundle", False)],
        links=[("plan_pro", "adfree"), ("plan_pro", "bundle"),
               ("plan_basic", "bundle")]
    );
    removed = reg.unsubscribe("plan_pro");
    assert removed == ["adfree", "plan_pro"];
    assert not reg.is_active("plan_pro");
    assert not reg.is_active("adfree");
    assert reg.is_active("bundle");      # diamond: other plan still holds it
}

test "shared_bundle_dies_with_last_holder_via_sweeper" {
    reg = load_graph(
        spec=[("plan_pro", "Pro", True), ("plan_basic", "Basic", True),
              ("bundle", "Bundle", False)],
        links=[("plan_pro", "bundle"), ("plan_basic", "bundle")]
    );
    _first = reg.unsubscribe("plan_pro");
    second = reg.unsubscribe("plan_basic");
    # sweeper picks the bundle up once its last holder is gone
    assert second == ["bundle", "plan_basic"];
    assert len(reg.subs.keys()) == 0;
}

test "deep_chain_unknown_ids_idempotent" {
    reg = load_graph(
        spec=[("plan_team", "Team", True), ("storage", "Storage", False),
              ("storage_plus", "Storage Plus", False)],
        links=[("plan_team", "storage"), ("storage", "storage_plus")]
    );
    assert reg.unsubscribe("ghost") == [];
    assert reg.unsubscribe("storage") == ["storage", "storage_plus"];
    assert reg.active() == ["plan_team"];
    assert reg.unsubscribe("storage") == [];   # re-unsubscribe: nothing new
}
