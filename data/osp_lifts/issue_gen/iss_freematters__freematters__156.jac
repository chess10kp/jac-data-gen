"""OSP lift for freematters/freematters#156."""

node Hook {
    has name: str;
    has command: str;
    has timeout: int = 10;
}

node Executable {
    has path: str;
    has bundled: bool = False;
    has recursive: bool = False;
}

node Process {
    has pid: int;
    has command: str;
    has alive: bool = True;
}

edge Resolves {}
edge Spawns {}

walker ResolvePath {
    has claimed: dict[str, bool] = {};
    has found: str = "";
    has selected: bool = False;

    can inspect_hook with Hook entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        print("inspecting hook");
        for exe in [here ->:Resolves:->][?:Executable] {
            visit :0: [exe];
        }
    }

    can inspect_executable with Executable entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        print("inspecting executable");
        if here.recursive == False and here.bundled == True {
            if self.selected == False {
                self.found = here.path;
                self.selected = True;
            }
        }
        for exe in [here ->:Resolves:->][?:Executable] {
            visit :0: [exe];
        }
    }
}

walker ProcessSweep {
    has claimed: dict[str, bool] = {};
    has targets: list[Process] = [];

    can sweep_process with Process entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        self.targets.append(here);
        print("observing process");
        for child in [here ->:Spawns:->][?:Process] {
            visit :0: [child];
        }
    }
}

def resolve_hook_path(hook_node: Hook) -> str {
    w = hook_node spawn ResolvePath(claimed={});
    return w.found;
}

def preflight_hook(hook_node: Hook) -> bool {
    path = resolve_hook_path(hook_node);
    return path != "" and hook_node.timeout > 0;
}

def has_process(process_node: Process, target_pid: int) -> bool {
    wk = process_node spawn ProcessSweep(claimed={});
    for item in wk.targets {
        if item.pid == target_pid {
            return True;
        }
    }
    return False;
}

def terminate_process_tree(process_node: Process, target_pid: int) -> list[int] {
    wk = process_node spawn ProcessSweep(claimed={});
    ids: list[int] = [];
    for item in wk.targets {
        ids.append(item.pid);
    }
    if target_pid not in ids {
        return [];
    }
    for item in wk.targets {
        item.alive = False;
    }
    return sorted(ids);
}
