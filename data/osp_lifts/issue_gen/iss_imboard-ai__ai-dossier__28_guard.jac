"""Standalone CLI binary build workflow DAG.
Provenance: imboard-ai/ai-dossier#28
"""

node Workflow {
    has wid: str;
}

node Stage {
    has sid: str;
    has label: str;
}

node Platform {
    has pid: str;
    has artifact: str;
}

edge Depends {}

edge Targets {}

def seed_workflow -> Workflow {
    wf = Workflow(wid="pkg");
    root ++> wf;
    checkout = Stage(sid="checkout", label="Checkout");
    wf ++> checkout;
    install = Stage(sid="install_deps", label="InstallDeps");
    checkout +>:Depends:+> install;
    build = Stage(sid="build_binary", label="BuildBinary");
    install +>:Depends:+> build;
    upload = Stage(sid="upload_release", label="UploadRelease");
    build +>:Depends:+> upload;
    p1 = Platform(pid="macos-x64", artifact="dossier-verify-macos-x64");
    wf ++> p1;
    build +>:Targets:+> p1;
    p2 = Platform(pid="macos-arm64", artifact="dossier-verify-macos-arm64");
    wf ++> p2;
    build +>:Targets:+> p2;
    p3 = Platform(pid="linux-x64", artifact="dossier-verify-linux-x64");
    wf ++> p3;
    build +>:Targets:+> p3;
    p4 = Platform(pid="linux-arm64", artifact="dossier-verify-linux-arm64");
    wf ++> p4;
    build +>:Targets:+> p4;
    p5 = Platform(pid="win-x64", artifact="dossier-verify-windows-x64.exe");
    wf ++> p5;
    build +>:Targets:+> p5;
    return wf;
}

def find_stage(wf: Workflow, sid: str) -> Stage | None {
    stages: list[Stage] = [wf ->][?:Stage];
    for st in stages {
        if st.sid == sid {
            return st;
        }
    }
    return None;
}

def find_platform(wf: Workflow, pid: str) -> Platform | None {
    plats: list[Platform] = [wf ->][?:Platform];
    for pl in plats {
        if pl.pid == pid {
            return pl;
        }
    }
    return None;
}

walker ClosureWalker {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];

    can walk with Stage entry {
        if here.sid in self.claimed {
            skip;
        }
        self.claimed[here.sid] = True;
        self.found.append(here.sid);
        print("closure", here.sid);
        kids: list[Stage] = [here ->:Depends:->][?:Stage];
        for kid in kids {
            visit :0: [kid];
        }
        if len(kids) == 0 {
            disengage;
        }
    }
}

walker OrderWalker {
    has claimed: dict[str, bool] = {};
    has order: list[str] = [];

    can plan with Stage entry {
        if here.sid in self.claimed {
            skip;
        }
        self.claimed[here.sid] = True;
        print("plan", here.sid);
        kids: list[Stage] = [here ->:Depends:->][?:Stage];
        for kid in kids {
            visit [kid];
        }
        self.order.append(here.sid);
        if len(kids) == 0 {
            disengage;
        }
    }
}

walker CycleWalker {
    has claimed: dict[str, bool] = {};
    has stack: dict[str, bool] = {};
    has cyclic: bool = False;

    can probe with Stage entry {
        if here.sid in self.stack {
            self.cyclic = True;
            print("cycle", here.sid);
            skip;
        }
        if here.sid in self.claimed {
            skip;
        }
        self.stack[here.sid] = True;
        print("probe", here.sid);
        kids: list[Stage] = [here ->:Depends:->][?:Stage];
        for kid in kids {
            visit [kid];
        }
        self.stack[here.sid] = False;
        self.claimed[here.sid] = True;
        if len(kids) == 0 {
            disengage;
        }
    }
}

def list_platforms -> list[str] {
    wf = seed_workflow();
    out: list[str] = [];
    plats: list[Platform] = [wf ->][?:Platform];
    for pl in plats {
        out.append(pl.pid);
    }
    return sorted(out);
}

def artifact_name(platform: str) -> str | None {
    wf = seed_workflow();
    pl = find_platform(wf, platform);
    if pl is None {
        return None;
    }
    return pl.artifact;
}

def build_order -> list[str] {
    wf = seed_workflow();
    st = find_stage(wf, "checkout");
    if st is None {
        return [];
    }
    w = st spawn OrderWalker(claimed={});
    return w.order;
}

def depends_closure(stage_id: str) -> list[str] {
    wf = seed_workflow();
    st = find_stage(wf, stage_id);
    if st is None {
        return [];
    }
    w = st spawn ClosureWalker(claimed={});
    return sorted(w.found);
}

def detects_dependency_cycle(extra_from: str | None = None, extra_to: str | None = None) -> bool {
    wf = seed_workflow();
    if extra_from is not None && extra_to is not None {
        src = find_stage(wf, extra_from);
        dst = find_stage(wf, extra_to);
        if src is not None && dst is not None {
            src +>:Depends:+> dst;
        }
    }
    st = find_stage(wf, "checkout");
    if st is None {
        return False;
    }
    w = st spawn CycleWalker(claimed={}, stack={});
    return w.cyclic;
}

test "list_platforms_sorted" {
    plats = list_platforms();
    assert plats == ["linux-arm64", "linux-x64", "macos-arm64", "macos-x64", "win-x64"];
}

test "artifact_name_known" {
    assert artifact_name("linux-x64") == "dossier-verify-linux-x64";
}

test "artifact_name_missing" {
    assert artifact_name("freebsd-x64") is None;
}

test "build_order_linear" {
    order = build_order();
    assert order == ["checkout", "install_deps", "build_binary", "upload_release"];
}

test "depends_closure_from_build" {
    closure = depends_closure("build_binary");
    assert closure == ["build_binary", "upload_release"];
}

test "detects_dependency_cycle_back_edge" {
    assert detects_dependency_cycle("upload_release", "checkout") is True;
}
