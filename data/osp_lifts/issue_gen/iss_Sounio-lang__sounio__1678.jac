"""OSP lift for Sounio-lang/sounio#1678."""

node Issue {
    has issue_id: str;
    has title: str;
}

node Site {
    has key: str;
    has path: str;
    has line: int;
    has fixed: bool = False;
}

edge Contains {}
edge References {}
edge Depends {}

obj Audit {
    has issue: Issue;
    has sites: list[Site] = [];
    has expected: int = 5;
    has hoisted: int = 5;
    has inplace: int = 0;
}

walker AuditWalk {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];
    has pending: list[str] = [];

    can step_issue with Issue entry {
        issue_claim: str = "issue:" + here.issue_id;
        if issue_claim in self.claimed { skip; }
        self.claimed[issue_claim] = True;
        print(here.issue_id);
        for site in [here ->:Contains:->][?:Site] {
            visit :0: [site];
        }
    }

    can step_site with Site entry {
        site_claim: str = "site:" + here.key;
        if site_claim in self.claimed { skip; }
        self.claimed[site_claim] = True;
        self.found.append(here.key);
        if here.fixed == False {
            self.pending.append(here.key);
        }
        print(here.path);
        for kid in [here ->:References:->][?:Site] {
            visit :0: [kid];
        }
        for kid in [here ->:Depends:->][?:Site] {
            visit :0: [kid];
        }
    }
}

def new_audit(issue_id: str, title: str) -> Audit {
    issue = Issue(issue_id=issue_id, title=title);
    return Audit(issue=issue);
}

def new_site(key: str, path: str, line: int) -> Site {
    return Site(key=key, path=path, line=line);
}

def register_candidate(audit: Audit, site: Site) -> None {
    audit.sites.append(site);
    audit.issue +>:Contains:+> site;
}

def link_reference(source: Site, target: Site) -> None {
    source +>:References:+> target;
}

def link_dependency(source: Site, target: Site) -> None {
    source +>:Depends:+> target;
}

def reachable_from(start: Site) -> list[str] {
    w = start spawn AuditWalk(claimed={});
    return sorted(w.found);
}

def unresolved(audit: Audit) -> list[str] {
    w = audit.issue spawn AuditWalk(claimed={});
    return sorted(w.pending);
}

def fix_site(audit: Audit, key: str) -> bool {
    for site in audit.sites {
        if site.key == key {
            site.fixed = True;
            return True;
        }
    }
    return False;
}

def record_measurements(audit: Audit, hoisted: int, inplace: int) -> None {
    audit.hoisted = hoisted;
    audit.inplace = inplace;
}

def acceptance(audit: Audit) -> dict[str, bool] {
    w = audit.issue spawn AuditWalk(claimed={});
    status: dict[str, bool] = {};
    status["reproducer"] = False;
    if audit.hoisted == audit.expected {
        if audit.inplace == audit.expected {
            status["reproducer"] = True;
        }
    }
    status["candidates"] = len(w.pending) == 0;
    status["gate"] = False;
    if status["reproducer"] == True {
        if status["candidates"] == True {
            status["gate"] = True;
        }
    }
    return status;
}
