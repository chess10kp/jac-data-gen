# OSP lift of Lindenfrost/ProgTrack-Release#186
node Animal {
    has aid: str;
    has sex: str = "U";
}

edge ParentOf {}

edge GhostContext {
    has kind: str = "sibling";
}

node Frame {
    has fid: str;
    has labels: dict[str, str] = {};
}

node FrameNode {
    has fid: str;
    has collides: bool = False;
}

edge Contains {}

walker SelectAnimals {
    has claimed: dict[str, bool] = {};
    has picks: list[str] = [];
    has found: list[str] = [];

    can gather with Animal entry {
        if here.aid in self.claimed { skip; }
        self.claimed[here.aid] = True;
        self.found.append(here.aid);
        parents: list[Animal] = [];
        for p in [here <-:ParentOf:-] {
            if p instanceof Animal {
                parents.append(p);
            }
        }
        visit parents;
    }

    can done with Animal exit {
        print("select:", self.found);
    }
}

walker ScopeGhosts {
    has depth: int = 4;
    has ghosts: dict[str, str] = {};
    has claimed: dict[str, bool] = {};

    can expand with Animal entry {
        if here.aid in self.claimed { skip; }
        self.claimed[here.aid] = True;
        # bounded sibling closure: peers sharing an in-scope parent
        for p in [here <-:ParentOf:-] {
            if p instanceof Animal {
                for sib in [p ->:ParentOf:->] {
                    if sib instanceof Animal {
                        if sib.aid != here.aid and sib.aid not in self.ghosts {
                            self.ghosts[sib.aid] = "sibling";
                        }
                    }
                }
            }
        }
        kids: list[Animal] = [];
        for k in [here ->:ParentOf:->] {
            if k instanceof Animal {
                kids.append(k);
            }
        }
        if self.depth > 0 {
            self.depth -= 1;
            visit kids;
        } else {
            print("scope done at", here.aid);
            disengage;
        }
    }
}

walker BuildGeometry {
    has claimed: dict[str, bool] = {};
    has ok: bool = False;

    can lay with Frame entry {
        if here.fid in self.claimed { skip; }
        self.claimed[here.fid] = True;
        nodes: list[FrameNode] = [];
        for fn in [here ->:Contains:->] {
            if fn instanceof FrameNode {
                nodes.append(fn);
            }
        }
        for fn in nodes {
            if fn.collides {
                here.ok = False;
                print("collision at", fn.fid);
                disengage;
            }
            here.labels[fn.fid] = "ok";
        }
        here.ok = True;
        print("geometry ok:", here.fid);
    }
}

# collect the in-scope closure from graph_root when root is picked
def scope_ancestors(graph_root: Animal, picks: list[str]) -> list[str] {
    found: list[str] = [];
    if graph_root.aid not in picks {
        return sorted(found);
    }
    w = graph_root spawn SelectAnimals(claimed={}, picks=picks, found=found);
    res: list[str] = [];
    for a in w.found {
        res.append(a);
    }
    return sorted(res);
}

# bounded sibling-ghost map seeded at graph_root
def sibling_ghosts(graph_root: Animal) -> dict[str, str] {
    w = graph_root spawn ScopeGhosts(claimed={}, ghosts={}, depth=4);
    return w.ghosts;
}

# frame geometry validation: any colliding frame node fails the frame
def validate_geometry(frame: Frame) -> bool {
    w = frame spawn BuildGeometry(claimed={}, ok=False);
    return w.ok;
}

test "sibling closure seeded at root" {
    a = Animal(aid="a");
    b = Animal(aid="b");
    c = Animal(aid="c");
    a +>:ParentOf:+> b;
    a +>:ParentOf:+> c;
    g = sibling_ghosts(b);
    assert g == {"a": "sibling", "c": "sibling"};
}

test "scope ancestors closure" {
    r = Animal(aid="r");
    m = Animal(aid="m");
    l = Animal(aid="l");
    r +>:ParentOf:+> m;
    m +>:ParentOf:+> l;
    out = scope_ancestors(r, ["r"]);
    assert out == ["l", "m", "r"];
    assert scope_ancestors(r, ["zzz"]) == [];
}

test "geometry ok frame" {
    f = Frame(fid="f1");
    n1 = FrameNode(fid="n1");
    n2 = FrameNode(fid="n2");
    f +>:Contains:+> n1;
    f +>:Contains:+> n2;
    assert validate_geometry(f) == True;
    assert f.labels == {"n1": "ok", "n2": "ok"};
}

test "geometry collision frame" {
    f = Frame(fid="f2");
    n1 = FrameNode(fid="n1");
    n2 = FrameNode(fid="n2", collides=True);
    f +>:Contains:+> n1;
    f +>:Contains:+> n2;
    assert validate_geometry(f) == False;
}

test "cycle tolerant scope walk" {
    r = Animal(aid="r");
    c = Animal(aid="c");
    r +>:ParentOf:+> c;
    c +>:ParentOf:+> r;
    out = scope_ancestors(r, ["r"]);
    assert out == ["c", "r"];
}
