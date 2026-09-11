# iss_2600hz-oscillator__patchtogether.live__2054.jac
# foxy volumetric bridge: 256x256 field ~24Hz on main thread (#2054) — dirty-track + quiesce lift
node Foxy { has fid: str; has quiesced: bool = false; has sig: int = 0; has ticks: int = 0; }
node Raster { has rid: str; has frozen: bool = false; }
node Surface { has sid: str; }
node Cell { has cid: str; }
edge RootLink {}
edge HasRaster {}
edge Drives {}
edge Contains {}

walker RasterCollector {
    has claimed: dict[str, bool] = {};
    has out: list[Raster] = [];
    can rc_foxy with Foxy entry {
        if here.fid in self.claimed { skip; }
        self.claimed[here.fid] = true;
        print(here.fid);
        for r in [here ->:HasRaster:->][?:Raster] { visit :0: [r]; }
    }
    can rc_raster with Raster entry {
        if here.rid in self.claimed { skip; }
        self.claimed[here.rid] = true;
        self.out.append(here);
        print(here.rid);
        visit [] else { disengage; }
    }
}
walker CellCollector {
    has claimed: dict[str, bool] = {};
    has cells: list[str] = [];
    can cc_foxy with Foxy entry {
        if here.fid in self.claimed { skip; }
        self.claimed[here.fid] = true;
        print(here.fid);
        for s in [here ->:Drives:->][?:Surface] { visit :0: [s]; }
    }
    can cc_surface with Surface entry {
        if here.sid in self.claimed { skip; }
        self.claimed[here.sid] = true;
        print(here.sid);
        for c in [here ->:Contains:->][?:Cell] { visit :0: [c]; }
        for n in [here ->:Drives:->][?:Surface] { visit :0: [n]; }
    }
    can cc_cell with Cell entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = true;
        self.cells.append(here.cid);
        print(here.cid);
        visit [] else { disengage; }
    }
}

def find_foxy(fid: str) -> Foxy | None {
    # scan root-anchored foxies
    for cand in [root ->:RootLink:->][?:Foxy] {
        if cand.fid == fid { return cand; }
    }
    return None;
}
def find_surface(sid: str) -> Surface | None {
    for cand in [root ->:RootLink:->][?:Surface] {
        if cand.sid == sid { return cand; }
    }
    return None;
}
def find_cell(cid: str) -> Cell | None {
    for cand in [root ->:RootLink:->][?:Cell] {
        if cand.cid == cid { return cand; }
    }
    return None;
}
def create_foxy(fid: str) -> str {
    got: Foxy | None = find_foxy(fid);
    if got is not None { return fid; }
    nd: Foxy = Foxy(fid=fid);
    root +>:RootLink:+> nd;
    return fid;
}
def add_raster(fid: str, rid: str, frozen: bool) -> bool {
    foxy: Foxy | None = find_foxy(fid);
    if foxy is None { return false; }
    # reuse if exists
    for r in [foxy ->:HasRaster:->][?:Raster] {
        if r.rid == rid { r.frozen = frozen; return true; }
    }
    nd: Raster = Raster(rid=rid, frozen=frozen);
    root +>:RootLink:+> nd;
    foxy +>:HasRaster:+> nd;
    return true;
}
def set_raster_frozen(fid: str, rid: str, frozen: bool) -> bool {
    foxy: Foxy | None = find_foxy(fid);
    if foxy is None { return false; }
    for r in [foxy ->:HasRaster:->][?:Raster] {
        if r.rid == rid { r.frozen = frozen; return true; }
    }
    return false;
}
def add_surface(fid: str, sid: str) -> bool {
    foxy: Foxy | None = find_foxy(fid);
    if foxy is None { return false; }
    if find_surface(sid) is not None {
        sf: Surface | None = find_surface(sid);
        if sf is not None { foxy +>:Drives:+> sf; }
        return true;
    }
    nd: Surface = Surface(sid=sid);
    root +>:RootLink:+> nd;
    foxy +>:Drives:+> nd;
    return true;
}
def connect_surfaces(a: str, b: str) -> bool {
    sa: Surface | None = find_surface(a);
    sb: Surface | None = find_surface(b);
    if sa is None { return false; }
    if sb is None { return false; }
    sa +>:Drives:+> sb;
    return true;
}
def add_cell(sid: str, cid: str) -> bool {
    surf: Surface | None = find_surface(sid);
    if surf is None { return false; }
    c: Cell | None = find_cell(cid);
    nd: Cell = c;
    if c is None {
        nd = Cell(cid=cid);
        root +>:RootLink:+> nd;
    }
    surf +>:Contains:+> nd;
    return true;
}
def quiesce_foxy(fid: str) -> bool {
    foxy: Foxy | None = find_foxy(fid);
    if foxy is None { return false; }
    foxy.quiesced = true;
    return true;
}
def get_signature(fid: str) -> int {
    foxy: Foxy | None = find_foxy(fid);
    if foxy is None { return 0; }
    return foxy.sig;
}
def get_tick_count(fid: str) -> int {
    foxy: Foxy | None = find_foxy(fid);
    if foxy is None { return 0; }
    return foxy.ticks;
}
def bridge_tick(fid: str) -> int {
    foxy: Foxy | None = find_foxy(fid);
    if foxy is None { return 0; }
    if foxy.quiesced { return foxy.sig; }
    # collect rasters via walker (once-only claim-map)
    w = foxy spawn RasterCollector(claimed={});
    # w.out holds rasters
    all_frozen: bool = true;
    has_any: bool = false;
    for r in w.out {
        has_any = true;
        if r.frozen == false { all_frozen = false; }
    }
    # dirty-track: if all three frozen and we have ticked before, skip field scan
    if has_any and all_frozen and foxy.ticks > 0 {
        print(foxy.sig);
        return foxy.sig;
    }
    foxy.ticks += 1;
    foxy.sig += 1;
    # fingerprint update simulates boxHeightfield3d+fieldToWavetable
    print(foxy.sig);
    return foxy.sig;
}
def get_reachable_cells(fid: str) -> list[str] {
    foxy: Foxy | None = find_foxy(fid);
    if foxy is None { return []; }
    w = foxy spawn CellCollector(claimed={});
    out: list[str] = w.cells;
    return out;
}

with entry {
    demo: Foxy = Foxy(fid="__demo__");
    root +>:RootLink:+> demo;
    w = demo spawn CellCollector(claimed={});
    print(w.cells);
}

# tests for iss_2600hz-oscillator__patchtogether.live__2054.jac — adversarial, no imports needed (guard concatenates)
test "bridge dirty tracking skips when all rasters frozen" {
    fid: str = "foxy-dirty-1";
    create_foxy(fid);
    add_raster(fid, "rA", false);
    add_raster(fid, "rB", false);
    add_raster(fid, "rC", false);
    s1: int = bridge_tick(fid);
    s2: int = bridge_tick(fid);
    assert(s2 == s1 + 1);
    set_raster_frozen(fid, "rA", true);
    set_raster_frozen(fid, "rB", true);
    set_raster_frozen(fid, "rC", true);
    s3: int = bridge_tick(fid);
    assert(s3 == s2);
    s4: int = bridge_tick(fid);
    assert(s4 == s2);
    set_raster_frozen(fid, "rB", false);
    s5: int = bridge_tick(fid);
    assert(s5 == s2 + 1);
}

test "quiesce freezes tick and signature" {
    fid: str = "foxy-quiesce-1";
    create_foxy(fid);
    add_raster(fid, "qrA", false);
    s1: int = bridge_tick(fid);
    assert(s1 == 1);
    ok: bool = quiesce_foxy(fid);
    assert(ok);
    s2: int = bridge_tick(fid);
    assert(s2 == s1);
    assert(get_tick_count(fid) == 1);
    assert(get_signature(fid) == s1);
}

test "diamond revisit deduplicates cells adversarial order" {
    fid: str = "foxy-diamond-1";
    create_foxy(fid);
    add_surface(fid, "s1");
    add_surface(fid, "s2");
    # both surfaces drive a shared diamond surface
    add_surface(fid, "sShared");
    # insertion order adversarial: connect s2 first, then s1, both to shared
    connect_surfaces("s2", "sShared");
    connect_surfaces("s1", "sShared");
    add_cell("sShared", "cX");
    add_cell("s1", "cA");
    add_cell("s2", "cB");
    # duplicate cell via shared surface reachable through two paths
    got: list[str] = get_reachable_cells(fid);
    got_sorted: list[str] = sorted(got);
    assert(got_sorted == ["cA", "cB", "cX"]);
    # second call must be stable (claim-map + skip, not disengage truncation)
    got2: list[str] = get_reachable_cells(fid);
    assert(sorted(got2) == got_sorted);
}

test "unknown id tolerance and cell diamond via shared cell node" {
    assert(get_signature("no-such-foxy") == 0);
    assert(get_tick_count("no-such-foxy") == 0);
    assert(bridge_tick("no-such-foxy") == 0);
    assert(quiesce_foxy("no-such-foxy") == false);
    assert(add_raster("no-such-foxy", "r1", false) == false);
    assert(add_surface("no-such-foxy", "sx") == false);
    assert(add_cell("no-surface", "cx") == false);
    assert(get_reachable_cells("no-such-foxy") == []);
    # shared cell node diamond: two surfaces contain same cid
    fid2: str = "foxy-shared-cell-1";
    create_foxy(fid2);
    add_surface(fid2, "sa");
    add_surface(fid2, "sb");
    add_cell("sa", "shared");
    add_cell("sb", "shared");
    cells: list[str] = get_reachable_cells(fid2);
    assert(sorted(cells) == ["shared"]);
}

test "faces-parity 33 cells path reach sorted" {
    fid: str = "foxy-parity-33";
    create_foxy(fid);
    add_surface(fid, "face");
    i: int = 0;
    while i < 33 {
        cid: str = "cell-" + str(i);
        add_cell("face", cid);
        i += 1;
    }
    got: list[str] = get_reachable_cells(fid);
    assert(len(got) == 33);
    srt: list[str] = sorted(got);
    # sorted order deterministic
    assert(srt[0] == "cell-0");
    assert(srt[1] == "cell-1");
}

test "cycle surface graph does not loop" {
    fid: str = "foxy-cycle-1";
    create_foxy(fid);
    add_surface(fid, "ca");
    add_surface(fid, "cb");
    add_surface(fid, "cc");
    connect_surfaces("ca", "cb");
    connect_surfaces("cb", "cc");
    connect_surfaces("cc", "ca");
    add_cell("ca", "c1");
    add_cell("cb", "c2");
    got: list[str] = get_reachable_cells(fid);
    assert(sorted(got) == ["c1", "c2"]);
}
