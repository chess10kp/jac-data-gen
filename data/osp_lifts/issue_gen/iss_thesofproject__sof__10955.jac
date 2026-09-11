node Codec {
    has cid: str;
    has kind: str;
    has active: bool = False;
}

edge ResumeDep {}

walker ReachCollect {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];
    can collect with Codec entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        self.found.append(here.cid);
        print(here.cid);
        kids: list[Codec] = [here ->:ResumeDep:->][?:Codec];
        for kid in kids {
            visit [kid];
        }
    }
}

walker ResumeOrder {
    has claimed: dict[str, bool] = {};
    has order: list[str] = [];
    can order_step with Codec entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        self.order.append(here.cid);
        print(here.cid);
        kids: list[Codec] = [here ->:ResumeDep:->][?:Codec];
        for kid in kids {
            visit :0: [kid];
        }
    }
}

walker WedgeScan {
    has claimed: dict[str, bool] = {};
    has has_hdmi: bool = False;
    has has_active_analog: bool = False;
    can scan with Codec entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        print(here.cid);
        if here.kind == "hdmi" {
            self.has_hdmi = True;
        }
        if here.kind == "analog" and here.active {
            self.has_active_analog = True;
        }
        kids: list[Codec] = [here ->:ResumeDep:->][?:Codec];
        for kid in kids {
            visit [kid];
        }
    }
}

def make_codec(cid: str, kind: str, active: bool) -> Codec {
    nd: Codec = Codec(cid=cid, kind=kind, active=active);
    return nd;
}

def link_codecs(src: Codec, dst: Codec) -> None {
    src +>:ResumeDep:+> dst;
}

def get_reachable(start_codec: Codec) -> list[str] {
    w = start_codec spawn ReachCollect(claimed={}, found=[]);
    return w.found;
}

def get_resume_order(start_codec: Codec) -> list[str] {
    w = start_codec spawn ResumeOrder(claimed={}, order=[]);
    return w.order;
}

def will_wedge_on_resume(start_codec: Codec) -> bool {
    w = start_codec spawn WedgeScan(claimed={}, has_hdmi=False, has_active_analog=False);
    return w.has_hdmi and w.has_active_analog;
}

def is_reachable(start_codec: Codec, target: str) -> bool {
    reachable: list[str] = get_reachable(start_codec);
    for cid in reachable {
        if cid == target {
            return True;
        }
    }
    return False;
}

with entry {
    d: Codec = Codec(cid="dsp", kind="dsp", active=False);
    a: Codec = Codec(cid="analog", kind="analog", active=True);
    h: Codec = Codec(cid="hdmi", kind="hdmi", active=False);
    root ++> d;
    d +>:ResumeDep:+> a;
    d +>:ResumeDep:+> h;
    w = d spawn ReachCollect(claimed={}, found=[]);
    print(w.found);
    root spawn ReachCollect(claimed={}, found=[]);
    print("sof mtl resume demo ready");
}
