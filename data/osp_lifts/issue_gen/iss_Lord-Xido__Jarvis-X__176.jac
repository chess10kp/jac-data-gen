# PROGRAM iss_Lord-Xido__Jarvis-X__176.jac

node ControlPlane {
    has project: str;
    has owner: str;
}

node Workstream {
    has wid: str;
    has title: str;
    has gate: str;
    has stage: str = "Working";
}

node Evidence {
    has workstream: str;
    has gate: str;
    has metric: str;
    has workload: str;
    has configuration: str;
    has reproducible: bool = false;
    has counsel_reviewed: bool = false;
    has timing_proven: bool = false;
    has codec_valid: bool = false;
    has rollback_verified: bool = false;
    has evaluation_ready: bool = false;
    has royalty_audited: bool = false;
}

node LicensePackage {
    has name: str;
    has evaluation_ready: bool = false;
    has royalty_audited: bool = false;
    has design_in: bool = false;
}

edge Contains {}
edge Depends {}
edge Supports {}
edge Packages {}

walker DependencyWalker {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];

    can collect with Workstream entry {
        if here.wid in self.claimed { skip; }
        self.claimed[here.wid] = True;
        self.found.append(here.wid);
        print(here.wid);
        for kid in [here ->:Depends:->][?:Workstream] {
            visit :0: [kid];
        }
    }
}

def make_control_plane(project: str, owner: str) -> ControlPlane {
    return ControlPlane(project=project, owner=owner);
}

def add_workstream(graph_root: ControlPlane, wid: str, title: str, gate: str) -> Workstream {
    item = Workstream(wid=wid, title=title, gate=gate);
    graph_root +>:Contains:+> item;
    return item;
}

def connect_dependency(item: Workstream, prerequisite: Workstream) -> bool {
    item +>:Depends:+> prerequisite;
    return True;
}

def record_evidence(item: Workstream, ev: Evidence) -> bool {
    item +>:Supports:+> ev;
    return True;
}

def find_workstream(graph_root: ControlPlane, wid: str) -> Workstream | None {
    for item in [graph_root ->:Contains:->][?:Workstream] {
        if item.wid == wid {
            return item;
        }
    }
    return None;
}

def dependency_closure(graph_root: Workstream) -> list[str] {
    w = graph_root spawn DependencyWalker(claimed={});
    return sorted(w.found);
}

def dependency_closure_by_id(graph_root: ControlPlane, wid: str) -> list[str] {
    item: Workstream | None = find_workstream(graph_root, wid);
    if item == None {
        return [];
    }
    return dependency_closure(item);
}

def gate_satisfied(item: Workstream, evidence: list[Evidence]) -> bool {
    for ev in evidence {
        if ev.workstream == item.wid and ev.gate == item.gate {
            valid: bool = ev.reproducible;
            valid = valid and ev.metric != "";
            valid = valid and ev.workload != "";
            valid = valid and ev.configuration != "";
            if item.gate == "IP" {
                valid = valid and ev.counsel_reviewed;
            } elif item.gate == "HARDWARE" {
                valid = valid and ev.timing_proven;
            } elif item.gate == "MEDIA" {
                valid = valid and ev.codec_valid;
            } elif item.gate == "SECURITY" {
                valid = valid and ev.rollback_verified;
            } elif item.gate == "LICENSING" {
                valid = valid and ev.evaluation_ready;
                valid = valid and ev.royalty_audited;
            }
            if valid {
                return True;
            }
        }
    }
    return False;
}

def promotion_stage(item: Workstream, evidence: list[Evidence]) -> str {
    if gate_satisfied(item, evidence) == False {
        return item.stage;
    }
    if item.stage == "Working" {
        return "Robust";
    } elif item.stage == "Robust" {
        return "Portable";
    } elif item.stage == "Portable" {
        return "Elegant";
    } elif item.stage == "Elegant" {
        return "Advanced";
    }
    return "Advanced";
}

def can_promote(item: Workstream, evidence: list[Evidence]) -> bool {
    return promotion_stage(item, evidence) != item.stage;
}

def add_license_package(graph_root: ControlPlane, package: LicensePackage) -> bool {
    graph_root +>:Packages:+> package;
    return True;
}

def licensing_ready(package: LicensePackage) -> bool {
    return package.evaluation_ready
        and package.royalty_audited
        and package.design_in;
}
