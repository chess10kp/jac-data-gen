"""ECC Pi session-start hooks: resolve a real Node runtime to stop recursive OMP spawn chains."""

edge Hosts: any --> any { }
edge Triggers: any --> any { }
edge Respawns: any --> any { has reason: str = "session_start"; }

node HostRuntime {
    has title: str = "";
    has year: int = 0;
    has available: bool = True;
    has exec_path: str = "";
    has release_name: str = "node";
    has bun_version: str = "";
    has hook_node_override: str = "";
    has use_exec_path_naively: bool = False;

    def is_node_runtime() -> bool {
        if self.release_name != "node" {
            return False;
        }
        if self.bun_version != "" {
            return False;
        }
        if self.exec_path.endswith("/node")
            or self.exec_path.endswith("/nodejs")
            or self.exec_path.endswith("/node.exe")
            or self.exec_path.endswith("/nodejs.exe")
            or self.exec_path == "node"
            or self.exec_path == "nodejs" {
            return True;
        }
        return False;
    }

    def resolve_hook_runtime() -> str {
        if self.hook_node_override != "" {
            return self.hook_node_override;
        }
        if self.is_node_runtime() {
            return self.exec_path;
        }
        return "node";
    }

    def pick_runtime() -> str {
        if self.use_exec_path_naively {
            return self.exec_path;
        }
        return self.resolve_hook_runtime();
    }
}

node HookSpec {
    has title: str = "";
    has year: int = 0;
    has available: bool = True;
    has hook_id: str = "session:start";
    has script: str = "run-with-flags.js";
    has profiles: str = "minimal,standard,strict";
}

walker SessionStartExecutor {
    has title: str = "";
    has year: int = 0;
    has available: bool = True;
    has max_depth: int = 6;
    has seen: list[str] = [];
    has launches: int = 0;
    has current_runtime: str = "";

    can start with Root entry {
        visit [->:Hosts:->] else { disengage; };
    }

    can on_host with HostRuntime entry {
        self.current_runtime = here.pick_runtime();
        mode = "naive-execPath" if here.use_exec_path_naively else "guarded-runtime";
        print(f"[{mode}] host={here.title} interpreter={self.current_runtime}");
        visit [->:Triggers:->] else { disengage; };
    }

    can execute with HookSpec entry {
        sig = f"{self.current_runtime}:{here.hook_id}";
        if sig in self.seen {
            print(f"  [CYCLE] {sig} re-entered after {self.launches} launches; disengaging");
            disengage;
        }
        self.seen.append(sig);
        self.launches += 1;
        print(
            f"  launch {self.launches}: {self.current_runtime} "
            f"{here.script} {here.profiles}"
        );
        is_omp_interp = (
            self.current_runtime.endswith("/omp")
            or self.current_runtime.endswith("/omp.exe")
            or self.current_runtime == "omp"
        );
        if is_omp_interp {
            if self.launches >= self.max_depth {
                print(f"  [TIMEOUT] handler timed out after 30000ms at depth {self.launches}");
                disengage;
            }
            visit [->:Respawns:->] else { disengage; };
        } else {
            print(f"  [OK] hook completed once under {self.current_runtime}");
            disengage;
        }
    }
}

with entry {
    print("=== compiled OMP: naive process.execPath (recursive) ===");
    hook_naive = HookSpec(title="ecc-session-start");
    omp_parent = HostRuntime(
        title="omp-parent",
        exec_path="/usr/bin/omp",
        release_name="node",
        bun_version="1.4.0",
        use_exec_path_naively=True
    );
    omp_child = HostRuntime(
        title="omp-child",
        exec_path="/usr/bin/omp",
        release_name="node",
        bun_version="1.4.0",
        use_exec_path_naively=True
    );
    root +>:Hosts:+> omp_parent;
    omp_parent +>:Triggers:+> hook_naive;
    hook_naive +>:Respawns(reason="resume"):+> omp_child;
    omp_child +>:Triggers:+> hook_naive;
    root spawn SessionStartExecutor(max_depth=5);

    print("=== compiled OMP: guarded runtime selects node ===");
    hook_guarded = HookSpec(title="ecc-session-start");
    omp_fixed = HostRuntime(
        title="omp-fixed",
        exec_path="/usr/bin/omp",
        release_name="node",
        bun_version="1.4.0",
        use_exec_path_naively=False
    );
    root +>:Hosts:+> omp_fixed;
    omp_fixed +>:Triggers:+> hook_guarded;
    root spawn SessionStartExecutor(max_depth=5);

    print("=== ECC_HOOK_NODE override ===");
    hook_override = HookSpec(title="ecc-session-start");
    omp_override = HostRuntime(
        title="omp-override",
        exec_path="/usr/bin/omp",
        release_name="node",
        bun_version="1.4.0",
        hook_node_override="/opt/node/bin/node",
        use_exec_path_naively=False
    );
    root +>:Hosts:+> omp_override;
    omp_override +>:Triggers:+> hook_override;
    root spawn SessionStartExecutor(max_depth=5);
}
