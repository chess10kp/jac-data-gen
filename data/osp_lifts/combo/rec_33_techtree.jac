"""Game tech tree, lifted to OSP.

Branches form a Subbranch hierarchy; technologies are Tech nodes attached
to branches via BelongsTo; prerequisites are Requires cross-links (a DAG).
Walkers replace the recursive branch descent and the prerequisite stack
walk. Cycle policy: the source tolerated prerequisite cycles via a visited
guard; the guard set is domain logic and survives.
"""
node Branch {
    has bid: str;
}

node Tech {
    has tid: str;
    has era: int;
}

"""Branch hierarchy: parent +>:Subbranch:+> child."""
edge Subbranch {}

"""Tech lives in a branch."""
edge BelongsTo {}

"""Prerequisite cross-link: tech +>:Requires:+> prerequisite."""
edge Requires {}

walker BranchDescender {
    """Recursive descent over Subbranch edges collecting every tech in the
    subtree. Guard set because shared subtrees can be re-entered."""
    has found: set[str] = set();
    has claimed: dict[str, bool] = {};

    can step with Branch entry {
        if here.bid in self.claimed {
            skip;
        }
        self.claimed[here.bid] = True;
        owned: list[Tech] = [here ->:BelongsTo:->];
        for t in owned {
            self.found.add(t.tid);
        }
        visit [->:Subbranch:->];
    }
}

walker PrereqPlanner {
    """Stack-equivalent walk over forward Requires edges collecting
    transitive prerequisites missing from the researched set."""
    has researched: set[str];
    has origin: str;
    has todo: set[str] = set();
    has claimed: dict[str, bool] = {};

    can step with Tech entry {
        if here.tid in self.claimed {
            skip;
        }
        self.claimed[here.tid] = True;
        if here.tid != self.origin and here.tid not in self.researched {
            self.todo.add(here.tid);
        }
        visit [->:Requires:->];
    }
}

obj TechTree {
    """Compatibility facade. Branch and tech ids are public API currency,
    so by_bid/by_tid are domain lookup state."""
    has by_bid: dict[str, Branch] = {};
    has by_tid: dict[str, Tech] = {};

    def add_branch(bid: str, parent: str | None = None) -> str {
        if bid in self.by_bid {
            raise ValueError("duplicate branch " + bid);
        }
        b := Branch(bid=bid);
        if parent is not None {
            p = self.by_bid[parent];
            p +>:Subbranch:+> b;
        }
        self.by_bid[bid] = b;
        return bid;
    }

    def add_tech(tid: str, bid: str, era: int) -> str {
        if tid in self.by_tid {
            raise ValueError("duplicate tech " + tid);
        }
        t := Tech(tid=tid, era=era);
        self.by_bid[bid] +>:BelongsTo:+> t;
        self.by_tid[tid] = t;
        return tid;
    }

    def require(tid: str, prereq_tid: str) -> None {
        self.by_tid[tid] +>:Requires:+> self.by_tid[prereq_tid];
    }

    def subtree_techs(bid: str) -> list[str] {
        w: BranchDescender = self.by_bid[bid] spawn BranchDescender();
        return sorted(w.found);
    }

    def remaining_prereqs(researched: set[str], tid: str) -> list[str] {
        w = self.by_tid[tid] spawn PrereqPlanner(
            researched=researched, origin=tid
        );
        return sorted(w.todo);
    }

    def can_research(researched: set[str], tid: str) -> bool {
        direct: list[Tech] = [self.by_tid[tid] ->:Requires:->];
        return all(p.tid in researched for p in direct);
    }

    def era_of(tid: str) -> int {
        return self.by_tid[tid].era;
    }
}
