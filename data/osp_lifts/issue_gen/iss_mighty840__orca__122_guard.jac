node Service {
    has sid: str;
    has ready: bool = False;
    has wait_for: list[str] = [];
}

node Registry {
    has services: dict[str, Service] = {};
}

node ReadyState {
    has all_ready: bool = True;
}

edge DependsOn {}

walker ReadinessWalk {
    has registry: Registry;
    has state: ReadyState;
    has claimed: dict[str, bool] = {};

    can step with Service entry {
        if here.sid in self.claimed { skip; }
        self.claimed[here.sid] = True;
        print(here.sid);

        for target in here.wait_for {
            if target in self.registry.services {
                if not self.registry.services[target].ready {
                    self.state.all_ready = False;
                }
            }
        }

        for dep in [here ->:DependsOn:->][?:Service] {
            visit :0: [dep];
        }
    }
}

def register_service(registry: Registry, service: Service) -> None {
    registry.services[service.sid] = service;
}

def add_dependency(front: Service, back: Service) -> None {
    front +>: DependsOn :+> back;
}

def all_waits_ready(root: Service, registry: Registry) -> bool {
    if root.sid == "" {
        return False;
    }
    state: ReadyState = ReadyState();
    root spawn ReadinessWalk(registry, state);
    return state.all_ready;
}

def set_ready(service: Service, value: bool) -> None {
    service.ready = value;
}

test "diamond dependencies are claimed once" {
    registry: Registry = Registry();
    frontend: Service = Service(sid="frontend", ready=True);
    left: Service = Service(sid="left", ready=True);
    right: Service = Service(sid="right", ready=True);
    backend: Service = Service(sid="backend", ready=True);

    frontend.wait_for.append("backend");
    register_service(registry, frontend);
    register_service(registry, left);
    register_service(registry, right);
    register_service(registry, backend);

    add_dependency(frontend, left);
    add_dependency(frontend, right);
    add_dependency(left, backend);
    add_dependency(right, backend);

    assert (all_waits_ready(frontend, registry));
}

test "unready wait target blocks startup" {
    registry: Registry = Registry();
    frontend: Service = Service(sid="frontend", ready=True);
    backend: Service = Service(sid="backend", ready=False);

    frontend.wait_for.append("backend");
    register_service(registry, frontend);
    register_service(registry, backend);

    assert (!all_waits_ready(frontend, registry));
}

test "unknown wait target is tolerated" {
    registry: Registry = Registry();
    frontend: Service = Service(sid="frontend", ready=True);

    frontend.wait_for.append("missing");
    register_service(registry, frontend);

    assert (all_waits_ready(frontend, registry));
}

test "service without waits is ready" {
    registry: Registry = Registry();
    service: Service = Service(sid="standalone", ready=False);
    register_service(registry, service);

    assert (all_waits_ready(service, registry));
}

test "readiness can change after registration" {
    registry: Registry = Registry();
    frontend: Service = Service(sid="frontend", ready=True);
    backend: Service = Service(sid="backend", ready=False);

    frontend.wait_for.append("backend");
    register_service(registry, frontend);
    register_service(registry, backend);

    assert (!all_waits_ready(frontend, registry));
    set_ready(backend, True);
    assert (all_waits_ready(frontend, registry));
}
