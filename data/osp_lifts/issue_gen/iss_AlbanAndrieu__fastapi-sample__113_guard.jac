"""AlbanAndrieu/fastapi-sample#113 topology-aware health propagation."""

edge RequiredDependency {}
edge OptionalDependency {}

node Service {
    has id: str;
    has local_state: str;
    has evidence_source: str = "local";
    has observation_age: int = 0;
    has stale: bool = False;
    has app_probe_failed: bool = False;
    has active_workloads: list[str] = [];
    has declared_service_id: str = "";
    has dependency_state: str = "unknown";
    has effective_state: str = "unknown";
    has required_dependencies: list[str] = [];
    has blocked_by: list[str] = [];
    has dependency_evidence: list[dict[str, str]] = [];
    has cycle_detected: bool = False;
}

walker Reach {
    has wanted: str;
    has claimed: dict[str, bool] = {};
    has found: bool = False;

    can search with Service entry {
        if self.found { skip; }
        if here.id in self.claimed {
            print("reach revisit: " + here.id);
            skip;
        }
        self.claimed[here.id] = True;
        if here.id == self.wanted {
            self.found = True;
            print("reach found: " + here.id);
            skip;
        }
        for kid in [here ->:RequiredDependency:->][?:Service] {
            visit :0: [kid];
        }
        print("reach scanned: " + here.id);
    }
}

walker DependencyAudit {
    has claimed: dict[str, bool] = {};
    has failed: bool = False;
    has unknown: bool = False;
    has cycle_detected: bool = False;

    can inspect with Service entry {
        if here.id in self.claimed {
            print("dependency revisit: " + here.id);
            skip;
        }
        self.claimed[here.id] = True;
        if here.local_state == "fail" {
            self.failed = True;
        }
        if here.local_state == "stopped" {
            self.failed = True;
        }
        if here.local_state == "unknown" {
            self.unknown = True;
        }
        if here.stale {
            self.unknown = True;
        }
        for kid in [here ->:RequiredDependency:->][?:Service] {
            probe = kid spawn Reach(wanted=here.id, claimed={});
            if probe.found {
                self.cycle_detected = True;
            }
            visit :0: [kid];
        }
        print("dependency audited: " + here.id);
    }
}

def new_service(
    service_id: str,
    local_state: str,
    evidence_source: str = "local",
    observation_age: int = 0,
    stale: bool = False,
    app_probe_failed: bool = False
) -> Service {
    return Service(
        id=service_id,
        local_state=local_state,
        evidence_source=evidence_source,
        observation_age=observation_age,
        stale=stale,
        app_probe_failed=app_probe_failed
    );
}

def add_required(source: Service, target: Service) -> None {
    source +>:RequiredDependency:+> target;
    return None;
}

def add_optional(source: Service, target: Service) -> None {
    source +>:OptionalDependency:+> target;
    return None;
}

def declare_service(app: Service, declared: Service) -> None {
    app.declared_service_id = declared.id;
    return None;
}

def locate(graph_root: Service, service_id: str) -> Service | None {
    w = graph_root spawn Reach(wanted=service_id, claimed={});
    if w.found {
        return graph_root;
    }
    return None;
}

def reconcile(source: Service) -> str {
    source.required_dependencies = [];
    source.blocked_by = [];
    source.dependency_evidence = [];
    source.cycle_detected = False;

    for target in [source ->:RequiredDependency:->][?:Service] {
        source.required_dependencies.append(target.id);
        source.dependency_evidence.append({
            "target_id": target.id,
            "target_state": target.local_state,
            "relation_type": "required",
            "observation_age": str(target.observation_age)
        });
        if target.local_state == "fail" {
            source.blocked_by.append(target.id);
        }
        if target.local_state == "stopped" {
            source.blocked_by.append(target.id);
        }
        if target.stale {
            source.blocked_by.append(target.id);
        }
    }

    w = source spawn DependencyAudit(claimed={});
    source.cycle_detected = w.cycle_detected;

    if w.failed {
        source.dependency_state = "fail";
    } else {
        if w.unknown {
            source.dependency_state = "unknown";
        } else {
            if w.cycle_detected {
                source.dependency_state = "unknown";
            } else {
                source.dependency_state = "healthy";
            }
        }
    }

    if source.local_state == "fail" {
        source.effective_state = "fail";
    } else {
        if source.local_state == "stopped" {
            source.effective_state = "fail";
        } else {
            if source.app_probe_failed {
                source.effective_state = "fail";
            } else {
                if source.local_state == "unknown" {
                    source.effective_state = "degraded";
                } else {
                    if source.stale {
                        source.effective_state = "degraded";
                    } else {
                        if source.dependency_state == "healthy" {
                            source.effective_state = "healthy";
                        } else {
                            source.effective_state = "degraded";
                        }
                    }
                }
            }
        }
    }
    return source.effective_state;
}

def reconcile_id(graph_root: Service, service_id: str) -> str {
    item = locate(graph_root, service_id);
    if item is None {
        print("unknown service: " + service_id);
        return "unknown";
    }
    return reconcile(item);
}

test "diamond revisit" {
    a = new_service("a", "healthy");
    b = new_service("b", "healthy");
    c = new_service("c", "healthy");
    d = new_service("d", "healthy");
    add_required(a, b);
    add_required(a, c);
    add_required(b, d);
    add_required(c, d);
    assert (reconcile(a) == "healthy");
    assert (sorted(a.required_dependencies) == ["b", "c"]);
    assert (len(a.dependency_evidence) == 2);
    assert (a.cycle_detected == False);
}

test "required cycle is surfaced" {
    a = new_service("a", "healthy");
    b = new_service("b", "healthy");
    c = new_service("c", "healthy");
    add_required(a, b);
    add_required(b, c);
    add_required(c, a);
    assert (reconcile(a) == "degraded");
    assert (a.cycle_detected);
    assert (a.dependency_state == "unknown");
}

test "unknown id is tolerated" {
    graph_root = new_service("root", "healthy");
    assert (locate(graph_root, "missing") is None);
    assert (reconcile_id(graph_root, "missing") == "unknown");
}

test "optional and stale dependencies" {
    service = new_service("web", "healthy");
    optional_bad = new_service("metrics", "fail");
    stale_required = new_service(
        "db",
        "healthy",
        evidence_source="runtime",
        observation_age=99,
        stale=True
    );
    add_optional(service, optional_bad);
    add_required(service, stale_required);
    assert (reconcile(service) == "degraded");
    assert (service.dependency_state == "unknown");
    assert (service.blocked_by == ["db"]);
    service.local_state = "fail";
    assert (reconcile(service) == "fail");
}

test "stopped app keeps declared service" {
    app = new_service("postgres-app", "stopped", evidence_source="truenas");
    declared = new_service("postgres", "healthy");
    declare_service(app, declared);
    assert (len(app.active_workloads) == 0);
    assert (app.declared_service_id == "postgres");
    assert (reconcile(app) == "fail");
}
