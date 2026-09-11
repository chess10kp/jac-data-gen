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
