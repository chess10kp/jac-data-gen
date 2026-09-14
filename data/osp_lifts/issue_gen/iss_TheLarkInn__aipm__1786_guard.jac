"""TheLarkInn/aipm#1786 build timing and dependency report."""

node BuildRoot {
    has label: str;
}

node BuildUnit {
    has key: str;
    has crate: str;
    has version: str;
    has seconds: float;
    has mode: str;
}

edge Contains {}
edge Depends {}

obj BuildReport {
    has anchor: BuildRoot;
    has total_seconds: float = 0.0;
    has compilation_units: int = 0;
}

walker ReportWalker {
    has anchor_id: str = "";
    has target: str = "";
    has claimed: dict[str, bool] = {};
    has units: list[BuildUnit] = [];
    has found: list[str] = [];

    can scan_root with BuildRoot entry {
        print("build report scan");
        if here.cid != self.anchor_id {
            skip;
        }
        for unit in [here ->:Contains:->][?:BuildUnit] {
            if self.target == "" {
                visit :0: [unit];
            } else if unit.key == self.target {
                visit :0: [unit];
            }
        }
    }

    can scan_unit with BuildUnit entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        self.units.append(here);
        print(here.key);
        if self.target != "" {
            self.found.append(here.key);
            for kid in [here ->:Depends:->][?:BuildUnit] {
                visit :0: [kid];
            }
        }
    }
}

def new_report() -> BuildReport {
    anchor = BuildRoot(label="workspace");
    root ++> anchor;
    return BuildReport(anchor=anchor);
}

def add_unit(report: BuildReport, key: str, crate: str, version: str,
             seconds: float, mode: str) -> BuildUnit {
    unit = BuildUnit(key=key, crate=crate, version=version,
                     seconds=seconds, mode=mode);
    report.anchor +>:Contains:+> unit;
    report.total_seconds += seconds;
    report.compilation_units += 1;
    return unit;
}

def link_by_id(report: BuildReport, source_key: str, target_key: str) -> bool {
    w = root spawn ReportWalker(anchor_id=report.anchor.cid, claimed={});
    source: BuildUnit | None = None;
    target: BuildUnit | None = None;
    for unit in w.units {
        if unit.key == source_key {
            source = unit;
        }
        if unit.key == target_key {
            target = unit;
        }
    }
    if source is None {
        return False;
    }
    if target is None {
        return False;
    }
    source +>:Depends:+> target;
    return True;
}

def dependency_closure(report: BuildReport, key: str) -> list[str] {
    w = root spawn ReportWalker(anchor_id=report.anchor.cid,
                                target=key, claimed={});
    return w.found;
}

def slowest_units(report: BuildReport, limit: int) -> list[str] {
    w = root spawn ReportWalker(anchor_id=report.anchor.cid, claimed={});
    answer: list[str] = [];
    used: dict[str, bool] = {};
    while len(answer) < limit {
        best: BuildUnit | None = None;
        for unit in w.units {
            if unit.key in used {
                skip;
            }
            if best is None {
                best = unit;
            } else if unit.seconds > best.seconds {
                best = unit;
            }
        }
        if best is None {
            break;
        }
        used[best.key] = True;
        answer.append(best.key);
    }
    return answer;
}

def duplicate_crates(report: BuildReport) -> list[str] {
    w = root spawn ReportWalker(anchor_id=report.anchor.cid, claimed={});
    names: list[str] = [];
    seen: dict[str, bool] = {};
    for left in w.units {
        for right in w.units {
            if left.crate == right.crate && left.version != right.version {
                if left.crate not in seen {
                    seen[left.crate] = True;
                    names.append(left.crate);
                }
            }
        }
    }
    return sorted(names);
}

test "diamond revisit and cycle closure" {
    report = new_report();
    add_unit(report, "a", "root", "1", 1.0, "build");
    add_unit(report, "b", "syn", "2", 26.7, "build");
    add_unit(report, "c", "rustls", "0.23", 23.0, "build");
    add_unit(report, "d", "regex", "1", 18.0, "build");
    add_unit(report, "e", "reqwest", "0.12", 19.2, "build");
    assert (link_by_id(report, "a", "b") == True);
    assert (link_by_id(report, "a", "c") == True);
    assert (link_by_id(report, "b", "d") == True);
    assert (link_by_id(report, "c", "e") == True);
    assert (link_by_id(report, "c", "d") == True);
    assert (link_by_id(report, "d", "a") == True);
    got = dependency_closure(report, "a");
    assert (sorted(got) == ["a", "b", "c", "d", "e"]);
}

test "unknown identifiers are tolerated" {
    report = new_report();
    add_unit(report, "aws", "aws-lc-sys", "0.40", 85.5, "run-custom-build");
    assert (link_by_id(report, "missing", "aws") == False);
    assert (link_by_id(report, "aws", "missing") == False);
    assert (len(dependency_closure(report, "missing")) == 0);
}

test "slowest units and empty limits" {
    report = new_report();
    add_unit(report, "aws", "aws-lc-sys", "0.40", 85.5, "run-custom-build");
    add_unit(report, "git", "libgit2-sys", "0.17", 72.7, "run-custom-build");
    add_unit(report, "syn", "syn", "2.0", 26.7, "build");
    assert (slowest_units(report, 0) == []);
    top = slowest_units(report, 2);
    assert (sorted(top) == ["aws", "git"]);
    assert (len(slowest_units(report, 20)) == 3);
}

test "duplicate crate versions and self cycle" {
    report = new_report();
    add_unit(report, "regex-old", "regex", "1.9", 10.0, "build");
    add_unit(report, "regex-new", "regex", "1.10", 18.0, "build");
    add_unit(report, "tower", "tower", "0.5", 8.0, "build");
    assert (link_by_id(report, "regex-old", "regex-old") == True);
    assert (sorted(dependency_closure(report, "regex-old")) == ["regex-old"]);
    assert (duplicate_crates(report) == ["regex"]);
    assert (report.compilation_units == 3);
}
