# iss_coryodaniel__arbor__23.jac — coryodaniel/arbor#23 dynamic schema-prefix recursive traversal

glob ALLOWED_PREFIXES = ["public", "acme", "contoso"];

node tree_row {
    has row_id: str;
    has schema_prefix: str;
}

edge child_of {}

def prefix_allowed(prefix: str) -> bool {
    for p in ALLOWED_PREFIXES {
        if p == prefix {
            return True;
        }
    }
    return False;
}

def row_key(r: tree_row) -> str {
    return r.row_id + "|" + r.schema_prefix;
}

walker find_w {
    has claimed: dict[str, bool] = {};
    has want_id: str = "";
    has want_prefix: str = "";
    has result: tree_row | None = None;

    can step with tree_row entry {
        k = row_key(here);
        if k in self.claimed {
            skip;
        }
        self.claimed[k] = True;
        if here.row_id == self.want_id and here.schema_prefix == self.want_prefix {
            self.result = here;
            print("find hit ", here.row_id, " ", here.schema_prefix);
            disengage;
        }
        nxt: list[tree_row] = [];
        for ch in [here ->:child_of:->][?:tree_row] {
            nxt.append(ch);
        }
        for par in [here <-:child_of:<-][?:tree_row] {
            nxt.append(par);
        }
        if len(nxt) > 0 {
            visit nxt;
        } else {
            disengage;
        }
    }
}

walker desc_w {
    has claimed: dict[str, bool] = {};
    has target_prefix: str = "";
    has max_depth: int = 0;
    has origin_id: str = "";
    has found: list[str] = [];
    has depths: dict[str, int] = {};

    can step with tree_row entry {
        k = row_key(here);
        if k in self.claimed {
            skip;
        }
        self.claimed[k] = True;
        if here.row_id == self.origin_id and here.schema_prefix == self.target_prefix {
            self.depths[k] = 0;
        }
        cd: int = 0;
        if k in self.depths {
            cd = self.depths[k];
        }
        if cd > 0 and cd <= self.max_depth and here.schema_prefix == self.target_prefix {
            self.found.append(here.row_id);
        }
        print("desc visit ", here.row_id, " depth=", cd);
        if cd >= self.max_depth {
            disengage;
        }
        kids: list[tree_row] = [];
        for ch in [here ->:child_of:->][?:tree_row] {
            if ch.schema_prefix == self.target_prefix {
                kids.append(ch);
            }
        }
        if len(kids) == 0 {
            disengage;
        }
        for kid in kids {
            kk = row_key(kid);
            self.depths[kk] = cd + 1;
        }
        visit :0: kids;
    }
}

walker anc_w {
    has claimed: dict[str, bool] = {};
    has target_prefix: str = "";
    has max_depth: int = 0;
    has origin_id: str = "";
    has found: list[str] = [];
    has depths: dict[str, int] = {};

    can climb with tree_row entry {
        k = row_key(here);
        if k in self.claimed {
            skip;
        }
        self.claimed[k] = True;
        if here.row_id == self.origin_id and here.schema_prefix == self.target_prefix {
            self.depths[k] = 0;
        }
        cd: int = 0;
        if k in self.depths {
            cd = self.depths[k];
        }
        if cd > 0 and cd <= self.max_depth and here.schema_prefix == self.target_prefix {
            self.found.append(here.row_id);
        }
        print("anc visit ", here.row_id, " depth=", cd);
        if cd >= self.max_depth {
            disengage;
        }
        pars: list[tree_row] = [];
        for par in [here <-:child_of:<-][?:tree_row] {
            if par.schema_prefix == self.target_prefix {
                pars.append(par);
            }
        }
        if len(pars) == 0 {
            disengage;
        }
        for par in pars {
            pk = row_key(par);
            self.depths[pk] = cd + 1;
        }
        visit :0: pars;
    }
}

def find_row(graph_root: tree_row, row_id: str, prefix: str) -> tree_row | None {
    w = graph_root spawn find_w(
        claimed={},
        want_id=row_id,
        want_prefix=prefix,
        result=None
    );
    return w.result;
}

def descendants(
    row_id: str,
    prefix: str,
    graph_root: tree_row,
    depth: int = 2147483647
) -> list[str] {
    if not prefix_allowed(prefix) {
        return [];
    }
    origin = find_row(graph_root, row_id, prefix);
    if origin is None {
        return [];
    }
    w = origin spawn desc_w(
        claimed={},
        target_prefix=prefix,
        max_depth=depth,
        origin_id=row_id,
        found=[],
        depths={}
    );
    out: list[str] = w.found;
    res: list[str] = sorted(out);
    print("descendants ", res);
    return res;
}

def ancestors(
    row_id: str,
    prefix: str,
    graph_root: tree_row,
    depth: int = 2147483647
) -> list[str] {
    if not prefix_allowed(prefix) {
        return [];
    }
    origin = find_row(graph_root, row_id, prefix);
    if origin is None {
        return [];
    }
    w = origin spawn anc_w(
        claimed={},
        target_prefix=prefix,
        max_depth=depth,
        origin_id=row_id,
        found=[],
        depths={}
    );
    out: list[str] = w.found;
    res: list[str] = sorted(out);
    print("ancestors ", res);
    return res;
}
