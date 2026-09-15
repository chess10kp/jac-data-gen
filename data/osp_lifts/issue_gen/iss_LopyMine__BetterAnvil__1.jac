"""PackScreen overlap with Recursive Resources — LopyMine/BetterAnvil#1."""

node Screen {
    has cid: str;
    has title: str;
}

node Widget {
    has cid: str;
    has kind: str;
    has x: int;
    has y: int;
    has w: int;
    has h: int;
}

node LayoutHandle {
    has screen: Screen;
    has by_id: dict[str, Widget] = {};
}

edge Hosts {}
edge Requires {}

def overlaps(a: Widget, b: Widget) -> bool {
    ax2 = a.x + a.w;
    ay2 = a.y + a.h;
    bx2 = b.x + b.w;
    by2 = b.y + b.h;
    if a.x >= bx2 { return False; }
    if b.x >= ax2 { return False; }
    if a.y >= by2 { return False; }
    if b.y >= ay2 { return False; }
    return True;
}

walker ResourceWalker {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];

    can walk_deps with Widget entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        self.found.append(here.cid);
        print("resource ", here.cid);
        kids: list[Widget] = [];
        for dep in [here ->:Requires:->][?:Widget] {
            kids.append(dep);
        }
        if kids {
            visit :0: kids;
        }
    }
}

walker ConflictWalker {
    has claimed: dict[str, bool] = {};
    has seen_widgets: list[Widget] = [];
    has pairs: list = [];

    can scan_host with Screen entry {
        print("pack ", here.cid);
        batch: list[Widget] = [];
        for wg in [here ->:Hosts:->][?:Widget] {
            batch.append(wg);
        }
        ids: list[str] = [];
        for wg in batch {
            ids.append(wg.cid);
        }
        ids = sorted(ids);
        ordered: list[Widget] = [];
        for cid in ids {
            for wg in batch {
                if wg.cid == cid {
                    ordered.append(wg);
                }
            }
        }
        if ordered {
            visit :0: ordered;
        }
    }

    can react with Widget entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        print("react ", here.cid);
        i = 0;
        while i < len(self.seen_widgets) {
            prior = self.seen_widgets[i];
            if overlaps(prior, here) {
                rec = [prior.cid, here.cid];
                self.pairs.append(rec);
                print("overlap ", prior.cid, here.cid);
            }
            i += 1;
        }
        self.seen_widgets.append(here);
    }
}

def build_pack_screen(screen_id: str, widget_specs: list) -> LayoutHandle {
    scr = Screen(cid=screen_id, title="PackScreen");
    root ++> scr;
    lh = LayoutHandle(screen=scr, by_id={});
    for spec in widget_specs {
        wid = spec[0];
        kind = spec[1];
        x = spec[2];
        y = spec[3];
        w = spec[4];
        h = spec[5];
        wg = Widget(cid=wid, kind=kind, x=x, y=y, w=w, h=h);
        scr +>:Hosts:+> wg;
        lh.by_id[wid] = wg;
    }
    return lh;
}

def collect_recursive_resources(store: LayoutHandle, start_id: str) -> list[str] {
    if start_id not in store.by_id {
        return [];
    }
    start_wg = store.by_id[start_id];
    wk = start_wg spawn ResourceWalker(claimed={});
    return sorted(wk.found);
}

def detect_layout_conflicts(store: LayoutHandle) -> list {
    wk = store.screen spawn ConflictWalker(claimed={}, seen_widgets=[]);
    return wk.pairs;
}
