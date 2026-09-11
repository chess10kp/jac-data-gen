"""DKG transitive queries: fold vs recursive CTE oracle. Source: lvlup-sw/exarchos#1816."""

node Claim {
    has key: str;
}

edge Supersedes {}

glob MAX_TRAVERSAL_DEPTH: int = 32;

walker FoldWalker {
    has claimed: dict[str, bool] = {};
    has reached: list[str] = [];
    has start: str = "";

    can begin with Root entry {
        for c in [-->][?:Claim] {
            if c.key == self.start {
                visit [c];
            }
        }
    }

    can step with Claim entry {
        if here.key in self.claimed {
            skip;
        }
        self.claimed[here.key] = True;
        self.reached.append(here.key);
        visit [->:Supersedes:->];
    }

    can finish with Root exit {
        report self.reached;
    }
}

walker CteOracle {
    has claimed: dict[str, bool] = {};
    has reached: list[str] = [];
    has budget: int = 0;

    can step with Claim entry {
        if here.key in self.claimed {
            skip;
        }
        self.claimed[here.key] = True;
        self.reached.append(here.key);
        if self.budget <= 0 {
            disengage;
        }
        for nxt in [here ->:Supersedes:->] {
            nxt spawn CteOracle(claimed=self.claimed, reached=self.reached, budget=self.budget - 1);
        }
    }
}

def _wire(triples: list[tuple[str, str]]) -> dict[str, Claim] {
    nodes: dict[str, Claim] = {};
    for (src, dst) in triples {
        if src not in nodes {
            nodes[src] = Claim(key=src);
            root ++> nodes[src];
        }
        if dst not in nodes {
            nodes[dst] = Claim(key=dst);
            root ++> nodes[dst];
        }
        nodes[src] +>:Supersedes:+> nodes[dst];
    }
    return nodes;
}

def transitive_query(start: str, triples: list[tuple[str, str]]) -> list[str] {
    nodes = _wire(triples);
    if start not in nodes {
        return [];
    }
    w = root spawn FoldWalker(start=start, claimed={}, reached=[]);
    return sorted(w.reports[0] if w.reports else []);
}

def dkg_reachable(seed: str, triples: list[tuple[str, str]]) -> list[str] {
    nodes = _wire(triples);
    anchor = nodes.get(seed);
    if anchor is None {
        return [];
    }
    w = anchor spawn CteOracle(claimed={}, reached=[], budget=MAX_TRAVERSAL_DEPTH);
    return sorted(w.reached);
}

def fold_oracle(seed: str, triples: list[tuple[str, str]]) -> bool {
    nodes = _wire(triples);
    if seed not in nodes {
        return True;
    }
    wfold = root spawn FoldWalker(start=seed, claimed={}, reached=[]);
    fold_res = sorted(wfold.reports[0] if wfold.reports else []);
    anchor = nodes[seed];
    woracle = anchor spawn CteOracle(claimed={}, reached=[], budget=MAX_TRAVERSAL_DEPTH);
    return fold_res == sorted(woracle.reached);
}

test "supersession chain fold matches oracle" {
    triples = [("cur", "p1"), ("p1", "p2")];
    assert transitive_query("cur", triples) == ["cur", "p1", "p2"];
    assert dkg_reachable("cur", triples) == ["cur", "p1", "p2"];
    assert fold_oracle("cur", triples) is True;
}

test "diamond supersession once per claim" {
    # Adversarial edge order: shared target reachable before deeper branches settle.
    triples = [("d0", "a"), ("d0", "b"), ("a", "t"), ("b", "t")];
    got = dkg_reachable("d0", triples);
    assert got.count("t") == 1;
    assert got == ["a", "b", "d0", "t"];
    assert fold_oracle("d0", triples) is True;
}

test "unknown claim id tolerated" {
    triples = [("a", "b")];
    assert transitive_query("missing", triples) == [];
    assert dkg_reachable("missing", triples) == [];
    assert fold_oracle("missing", triples) is True;
}
