# iss_stefankroes__ancestry__440.jac
# stefankroes/ancestry#440 — bulk ancestor preload to avoid N+1 full_name lookups.

node Hub {}

node Area {
    has cid: str;
    has name: str;
    has full_name_cache: str = "";
    has ancestors_loaded: bool = False;
}

edge Parent {}

node Person {
    has pid: str;
    has name: str;
    has area_id: str;
}

node QueryMeter {
    has ancestor_loads: int = 0;
}

walker FindArea {
    has target: str = "";
    has found: Area | None = None;
    has claimed: dict[str, bool] = {};

    can boot with Hub entry {
        for kid in [here -->][?:Area] {
            visit :0: [kid];
        }
    }

    can seek with Area entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        if here.cid == self.target {
            self.found = here;
            disengage;
        }
        for ch in [here <-:Parent:<-][?:Area] {
            visit :0: [ch];
        }
    }
}

walker CollectChain {
    has claimed: dict[str, bool] = {};
    has nodes: list[Area] = [];

    can ascend with Area entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        self.nodes.append(here);
        for par in [here ->:Parent:->][?:Area] {
            visit [par];
        }
    }
}

walker BulkPreload {
    has claimed: dict[str, bool] = {};
    has targets: dict[str, bool] = {};
    has filled: dict[str, bool] = {};
    has count: int = 0;

    can scan with Area entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        if here.cid in self.targets {
            sub = here spawn CollectChain(claimed={});
            parts: list[str] = [];
            j = len(sub.nodes) - 1;
            while j >= 0 {
                nd = sub.nodes[j];
                parts.append(nd.name);
                if nd.cid not in self.filled {
                    nd.full_name_cache = _join(parts, " - ");
                    nd.ancestors_loaded = True;
                    self.filled[nd.cid] = True;
                    self.count += 1;
                }
                j -= 1;
            }
        }
        for ch in [here <-:Parent:<-][?:Area] {
            visit :0: [ch];
        }
    }

    can boot with Hub entry {
        for kid in [here -->][?:Area] {
            visit :0: [kid];
        }
    }
}

walker DemoPrint {
    has claimed: dict[str, bool] = {};

    can boot with Hub entry {
        for kid in [here -->][?:Area] {
            visit :0: [kid];
        }
    }

    can show with Area entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        print([here.cid, here.full_name_cache]);
        for ch in [here <-:Parent:<-][?:Area] {
            visit :0: [ch];
        }
    }
}

def _hub -> Hub {
    for kid in [root -->][?:Hub] {
        return kid;
    }
    h = Hub();
    root ++> h;
    return h;
}

def _meter -> QueryMeter {
    for kid in [root -->][?:QueryMeter] {
        return kid;
    }
    m = QueryMeter();
    root ++> m;
    return m;
}

def _join(parts: list[str], sep: str) -> str {
    out: str = "";
    i = 0;
    while i < len(parts) {
        if i > 0 {
            out += sep;
        }
        out += parts[i];
        i += 1;
    }
    return out;
}

def reset_query_meter {
    _meter().ancestor_loads = 0;
}

def ancestor_query_count -> int {
    return _meter().ancestor_loads;
}

def add_area(cid: str, name: str, parent_cid: str | None = None) -> Area {
    nd = Area(cid=cid, name=name);
    _hub() ++> nd;
    if parent_cid != None {
        pw = _hub() spawn FindArea(target=parent_cid);
        if pw.found != None {
            nd +>:Parent:+> pw.found;
        }
    }
    return nd;
}

def add_person(pid: str, name: str, area_id: str) -> Person {
    p = Person(pid=pid, name=name, area_id=area_id);
    root ++> p;
    return p;
}

def preload_ancestry(area_ids: list[str]) -> int {
    tgts: dict[str, bool] = {};
    i = 0;
    while i < len(area_ids) {
        tgts[area_ids[i]] = True;
        i += 1;
    }
    w = _hub() spawn BulkPreload(targets=tgts, filled={});
    return w.count;
}

def area_full_name(area_id: str) -> str {
    fw = _hub() spawn FindArea(target=area_id);
    if fw.found == None {
        return "";
    }
    nd = fw.found;
    if nd.full_name_cache != "" {
        return nd.full_name_cache;
    }
    _meter().ancestor_loads += 1;
    cw = nd spawn CollectChain(claimed={});
    parts: list[str] = [];
    k = len(cw.nodes) - 1;
    while k >= 0 {
        parts.append(cw.nodes[k].name);
        k -= 1;
    }
    return _join(parts, " - ");
}

def people_area_full_names(person_ids: list[str] | None = None) -> list[list[str]] {
    want: dict[str, bool] = {};
    if person_ids != None {
        i = 0;
        while i < len(person_ids) {
            want[person_ids[i]] = True;
            i += 1;
        }
    }
    people: list[Person] = [];
    for kid in [root -->][?:Person] {
        people.append(kid);
    }
    area_ids: list[str] = [];
    picked: list[Person] = [];
    i = 0;
    while i < len(people) {
        p = people[i];
        if person_ids == None or p.pid in want {
            picked.append(p);
            area_ids.append(p.area_id);
        }
        i += 1;
    }
    preload_ancestry(area_ids);
    rows: list[list[str]] = [];
    i = 0;
    while i < len(picked) {
        p = picked[i];
        rows.append([p.name, area_full_name(p.area_id)]);
        i += 1;
    }
    return sorted(rows);
}

with entry {
    reset_query_meter();
    add_area("r", "Earth", None);
    add_area("eu", "Europe", "r");
    add_area("fr", "France", "eu");
    add_person("p1", "Alice", "fr");
    preload_ancestry(["fr"]);
    root spawn DemoPrint;
}
