# Lifting hashicorp/terraform#27248: dynamically-recursive child module
# references. Models a module dependency graph (source / count / for_each
# expansions as DEP edges) and detects recursive module references with a
# claim-map driven walker, so `init` can fail fast with a deterministic
# recursion report instead of blowing the stack.

node Mod {
    has mid: str;
    has source: str = "";
}

edge DEP {
    has via: str = "count";
}

# Creates a module node anchored under root; returns the instance.
def add_mod(mid: str, source: str) -> Mod {
    m = Mod(mid=mid, source=source);
    root ++> m;
    return m;
}

# Declares that child module `a` instantiates module `b` via an expansion
# expression (count / for_each / static source).
def link(a: Mod, b: Mod, via: str) -> None {
    a +>:DEP(via=via):+> b;
}

# Deterministic DFS closure of reachable module ids, cycle-safe.
def closure(groot: Mod) -> list[str] {
    wk = groot spawn Detect(claimed={});
    return wk.order;
}

# Returns the ids of nodes observed in a recursion (revisit), else [].
def find_recursion(groot: Mod) -> list[str] {
    wk = groot spawn Detect(claimed={});
    return wk.cycle;
}

walker Detect {
    has claimed: dict[str, bool] = {};
    has order: list[str] = [];
    has cycle: list[str] = [];

    can step with Mod entry {
        # claim-map + skip cycle policy; revisits are recorded, never fatal
        if here.mid in self.claimed {
            if len(self.cycle) == 0 {
                self.cycle.append(here.mid);
            }
            skip;
        }
        self.claimed[here.mid] = True;
        self.order.append(here.mid);
        kids: list[Mod] = [here ->:DEP:->][?:Mod];
        visit kids;
    }
}
