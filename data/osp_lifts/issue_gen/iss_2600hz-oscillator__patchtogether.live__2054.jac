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
