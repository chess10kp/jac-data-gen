node Snapshot {
    has version: str;
}

node Symbol {
    has sid: str;
    has origin: str = "source";
}

edge DirectCall {}
edge AliasCall {}
edge ApproximateCall {}

obj CallGraphService {
    has snapshot: Snapshot;
    has precision: str = "balanced";
    has symbols: dict[str, Symbol] = {};
    has cache: dict[str, list[str]] = {};
}

walker CallReach {
    has claimed: dict[str, bool] = {};
    has precision: str = "balanced";
    has found: list[str] = [];

    can collect with Symbol entry {
        if here.sid in self.claimed {
            skip;
        }
        self.claimed[here.sid] = True;
        self.found.append(here.sid);
        print(here.sid);

        for kid in [here ->:DirectCall:->][?:Symbol] {
            visit :0: [kid];
        }

        if self.precision != "fast" {
            for kid in [here ->:AliasCall:->][?:Symbol] {
                visit :0: [kid];
            }
        }

        if self.precision == "sound" {
            for kid in [here ->:ApproximateCall:->][?:Symbol] {
                visit :0: [kid];
            }
        }
    }
}

def new_service(snapshot_id: str, precision: str = "balanced")
    -> CallGraphService {
    snapshot = Snapshot(version=snapshot_id);
    service = CallGraphService(snapshot=snapshot);
    set_precision(service, precision);
    return service;
}

def set_precision(service: CallGraphService, precision: str) -> None {
    if precision == "fast" {
        service.precision = "fast";
    } else {
        if precision == "sound" {
            service.precision = "sound";
        } else {
            service.precision = "balanced";
        }
    }
    service.cache = {};
}

def register_symbol(
    service: CallGraphService,
    sid: str,
    origin: str = "source"
) -> Symbol {
    symbol = Symbol(sid=sid, origin=origin);
    service.symbols[sid] = symbol;
    service.cache = {};
    return symbol;
}

def add_call(
    service: CallGraphService,
    caller_id: str,
    callee_id: str,
    kind: str = "direct"
) -> None {
    if caller_id not in service.symbols {
        return;
    }
    if callee_id not in service.symbols {
        return;
    }

    caller = service.symbols[caller_id];
    callee = service.symbols[callee_id];

    if kind == "direct" {
        caller +>:DirectCall:+> callee;
    } else {
        if kind == "alias" {
            caller +>:AliasCall:+> callee;
        } else {
            caller +>:ApproximateCall:+> callee;
        }
    }
    service.cache = {};
}

def invalidate(service: CallGraphService) -> None {
    service.cache = {};
}

def query_calls(
    service: CallGraphService,
    entry_id: str,
    cancelled: bool = False
) -> list[str] {
    if cancelled {
        return [];
    }
    if entry_id not in service.symbols {
        return [];
    }

    key = service.snapshot.version + "|" + service.precision + "|" + entry_id;
    if key in service.cache {
        return service.cache[key];
    }

    graph_root = service.symbols[entry_id];
    w = graph_root spawn CallReach(
        claimed={},
        precision=service.precision
    );
    result: list[str] = sorted(w.found);
    service.cache[key] = result;
    return result;
}
