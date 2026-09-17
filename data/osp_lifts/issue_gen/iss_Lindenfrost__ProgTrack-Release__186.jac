# Lift of Lindenfrost/ProgTrack-Release#186
# Heritage Track first-render, sibling-ghost scope closure, ancestor expansion.

node Animal {
    has aid: str;
    has archived: bool = False;
}

edge ParentOf {}
edge PartnerOf {}
edge GhostContext {}

def get_animal(reg: dict[str, Animal], aid: str) -> Animal | None {
    # unknown-id tolerance: return None, never raise
    if aid in reg {
        return reg[aid];
    }
    return None;
}

def expand_ancestors(seeds: list[Animal], depth: int) -> list[Animal] {
    # bounded ancestor expansion (SelectedAnimalsStrategy)
    scope: dict[str, bool] = {};
    out: list[Animal] = [];
    frontier: list[Animal] = [];
    for s in seeds { frontier.append(s); }
    d: int = 0;
    while d <= depth && len(frontier) > 0 {
        nxt: list[Animal] = [];
        for a in frontier {
            if a.aid in scope { continue; }
            scope[a.aid] = True;
            out.append(a);
            for p in [a ->:ParentOf:->][?:Animal] {
                if p.aid not in scope { nxt.append(p); }
            }
        }
        frontier = nxt;
        d += 1;
    }
    return out;
}

def sibling_ghost_closure(scope: list[Animal]) -> list[Animal] {
    # one bounded pass: stage newly found context nodes so later
    # family-completeness evaluation sees them (no recursive expansion)
    staged: dict[str, Animal] = {};
    ghosts: list[Animal] = [];
    for a in scope { staged[a.aid] = a; }
    for a in scope {
        # parents already in scope expose their siblings as ghosts
        for p in [a ->:ParentOf:->][?:Animal] {
            if p.aid not in staged { staged[p.aid] = p; ghosts.append(p); }
            for sib in [p <-:ParentOf:<-][?:Animal] {
                if sib.aid not in staged { staged[sib.aid] = sib; ghosts.append(sib); }
            }
        }
        # missing genetic co-parent needed to make the visible family complete
        for part in [a ->:PartnerOf:->][?:Animal] {
            if part.aid not in staged { staged[part.aid] = part; ghosts.append(part); }
        }
        for part2 in [a <-:PartnerOf:<-][?:Animal] {
            if part2.aid not in staged { staged[part2.aid] = part2; ghosts.append(part2); }
        }
    }
    return ghosts;
}

walker HeritageRender {
    has selected: list[str] = [];
    has depth: int = 8;
    has scope: list[Animal] = [];
    has ghosts: list[Animal] = [];
    has reg: dict[str, Animal] = {};

    can step with Animal entry {
        # first-render safety: claim-map dedup, never disengage on revisit
        if here.aid in self.reg { skip; }
        self.reg[here.aid] = here;
        seeds: list[Animal] = [];
        for aid in self.selected {
            a = get_animal(self.reg, aid);
            if a is not None { seeds.append(a); }
        }
        # pass 1: ancestor expansion; pass 2: staged ghost closure on result
        self.scope = expand_ancestors(seeds, self.depth);
        self.ghosts = sibling_ghost_closure(self.scope);
        # deny archived-only render: invalid geometry guard
        ok: bool = False;
        for a in self.scope { if not a.archived { ok = True; } }
        if not ok { print("invalid geometry"); disengage; }
        print("rendered " + str(len(self.scope)) + " scope, "
              + str(len(self.ghosts)) + " ghosts");
        disengage;
    }
}

def render_heritage(root_node: Animal, selected: list[str]) -> HeritageRender {
    w = root_node spawn HeritageRender(selected=selected);
    return w;
}
