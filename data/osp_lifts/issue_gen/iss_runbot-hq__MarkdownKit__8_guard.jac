# iss_runbot-hq__MarkdownKit__8.jac
"""Package assessment graph for runbot-hq/MarkdownKit#8."""

node Package {
    has cid: str;
    has name: str;
    has version: str;
}

node Finding {
    has cid: str;
    has fid: str;
    has title: str;
    has category: str;
    has severity: int = 0;
}

edge Includes {}
edge References {}

walker AssessmentWalker {
    has wanted: list[str] = [];
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];
    has total: int = 0;

    can scan_package with Package entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        print("scanning package");
        for finding in [here ->:Includes:->][?:Finding] {
            if finding.fid in self.wanted {
                visit :0: [finding];
            }
        }
    }

    can scan_finding with Finding entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        print("scanning finding");
        self.found.append(here.fid);
        self.total = self.total + here.severity;
        for related in [here ->:References:->][?:Finding] {
            visit :0: [related];
        }
    }
}

def make_package(package_id: str, name: str, version: str) -> Package {
    return Package(
        cid="package:" + package_id,
        name=name,
        version=version
    );
}

def add_finding(
    package: Package,
    finding_id: str,
    title: str,
    severity: int,
    category: str
) -> Finding {
    finding = Finding(
        cid=finding_id,
        fid=finding_id,
        title=title,
        severity=severity,
        category=category
    );
    package +>:Includes:+> finding;
    return finding;
}

def link_finding(left: Finding, right: Finding) -> None {
    left +>:References:+> right;
}

def collect_finding_ids(
    graph_root: Package,
    start_ids: list[str]
) -> list[str] {
    w = graph_root spawn AssessmentWalker(
        wanted=start_ids,
        claimed={}
    );
    return sorted(w.found);
}

def risk_score(graph_root: Package, start_ids: list[str]) -> int {
    w = graph_root spawn AssessmentWalker(
        wanted=start_ids,
        claimed={}
    );
    return w.total;
}

test "diamond revisit claims once" {
    pkg = make_package("markdownkit", "MarkdownKit", "0.1");
    a = add_finding(pkg, "a", "parser recursion", 2, "correctness");
    b = add_finding(pkg, "b", "pool stack limit", 3, "performance");
    c = add_finding(pkg, "c", "platform reach", 1, "platform");
    d = add_finding(pkg, "d", "package metadata", 4, "packaging");

    link_finding(a, c);
    link_finding(a, b);
    link_finding(b, d);
    link_finding(c, d);

    assert (collect_finding_ids(pkg, ["a"]) == ["a", "b", "c", "d"]);
    assert (risk_score(pkg, ["a"]) == 10);
}

test "unknown ids are ignored" {
    pkg = make_package("markdownkit", "MarkdownKit", "0.1");
    add_finding(pkg, "known", "integer overflow", 5, "correctness");

    assert (collect_finding_ids(pkg, ["missing", "known", "missing"]) == ["known"]);
    assert (risk_score(pkg, ["missing"]) == 0);
}

test "empty starts produce empty assessment" {
    pkg = make_package("markdownkit", "MarkdownKit", "0.1");
    add_finding(pkg, "zero", "no impact", 0, "correctness");

    assert (collect_finding_ids(pkg, []) == []);
    assert (risk_score(pkg, []) == 0);
}

test "zero severity finding remains visible" {
    pkg = make_package("markdownkit", "MarkdownKit", "0.1");
    add_finding(pkg, "zero", "safe fallback", 0, "correctness");

    assert (collect_finding_ids(pkg, ["zero"]) == ["zero"]);
    assert (risk_score(pkg, ["zero"]) == 0);
}
