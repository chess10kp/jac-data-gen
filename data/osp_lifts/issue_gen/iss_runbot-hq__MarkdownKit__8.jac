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
