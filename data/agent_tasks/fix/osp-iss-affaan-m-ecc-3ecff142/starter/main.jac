"""ECC hook runtime selection under compiled Oh My Pi (OMP/Bun).

Models the recursive-spawn scenario from issue #2909:
the host executable must NOT be reused as the hook interpreter when
the host is a compiled OMP/Bun binary. A walker traverses the graph
of "hook candidates" (Host, Override, Default) and selects a safe
runtime, reporting the chain of reasoning.
"""

node Host {
    has name: str = "";
    has release_name: str = "";
    has bun_version: str = "";
    has exec_path: str = "";
}

node Override {
    has path: str = "";
    has source: str = "";
}

node DefaultRuntime {
    has binary: str = "node";
}

edge Candidate { has priority: int = 0; }
edge Resolves { has reason: str = ""; }

walker HookRuntimeResolver {
    has override_path: str = "";
    has chosen: str = "";
    has reason: str = "";

    can start with Root entry {
        # Walk to all candidate runtimes (Override + DefaultRuntime)
        # via typed Candidate edges.
        visit [->:Candidate:->];
    }

    can pick from Override | DefaultRuntime | Host entry {
        # The shared "is this a real node runtime?" decision lives on
        # a base node method so the union ability can call it without
        # caring which kind of node it landed on.
        if here.is_real_node_runtime() {
            self.chosen = here.runtime_path();
            self.reason = here.runtime_reason();
        }
        visit [->:Candidate:->];
    }
}

# ---------- runtime helpers attached to every candidate node ----------

node RuntimeCandidate {
    def is_real_node_runtime() -> bool {
        return False;
    }
    def runtime_path() -> str {
        return "";
    }
    def runtime_reason() -> str {
        return "";
    }
}

node Host(RuntimeCandidate) {
    has name: str = "";
    has release_name: str = "";
    has bun_version: str = "";
    has exec_path: str = "";

    override def is_real_node_runtime() -> bool {
        bun = self.bun_version;
        basename = self.exec_path.split("/")[-1] if self.exec_path else "";
        node_like = basename.lower().startswith("node");
        return (
            self.release_name == "node"
            and bun == ""
            and node_like
        );
    }
    override def runtime_path() -> str {
        return self.exec_path;
    }
    override def runtime_reason() -> str {
        return "host is plain Node";
    }
}

node Override(RuntimeCandidate) {
    has path: str = "";
    has source: str = "";

    override def is_real_node_runtime() -> bool {
        return self.path != "";
    }
    override def runtime_path() -> str {
        return self.path;
    }
    override def runtime_reason() -> str {
        return self.source;
    }
}

node DefaultRuntime(RuntimeCandidate) {
    has binary: str = "node";

    override def is_real_node_runtime() -> bool {
        return True;
    }
    override def runtime_path() -> str {
        return self.binary;
    }
    override def runtime_reason() -> str {
        return "fallback to PATH 'node'";
    }
}

walker RuntimePicker {
    has override_path: str = "";
    has chosen: str = "";
    has reason: str = "";

    can start with Root entry {
        visit [->:Candidate:->];
    }

    can pick with Host entry {
        # Host is a candidate only if it qualifies as a real Node runtime.
        if here.is_real_node_runtime() {
            self.chosen = here.runtime_path();
            self.reason = here.runtime_reason();
        }
        visit [->:Candidate:->];
    }

    can pick_override with Override entry {
        # Override always wins when supplied (highest priority edge).
        self.chosen = here.runtime_path();
        self.reason = here.runtime_reason();
        visit [->:Candidate:->];
    }

    can pick_default with DefaultRuntime entry {
        # Only adopt the default if nothing better has been picked.
        if self.chosen == "" {
            self.chosen = here.runtime_path();
            self.reason = here.runtime_reason();
        }
        visit [->:Candidate:->];
    }
}

# ---------- demo: three scenarios from the issue's requirements ----------

with entry {
    # Scenario A: plain Node host. Hook may reuse execPath.
    node_host = Host(
        name="plain-node",
        release_name="node",
        bun_version="",
        exec_path="/usr/bin/node",
    );
    # Scenario B: compiled OMP/Bun host. execPath MUST be rejected
    # because it would re-spawn the OMP binary recursively.
    omp_host = Host(
        name="omp-compiled",
        release_name="node",
        bun_version="1.4.0",
        exec_path="/opt/omp/omp",
    );
    # Scenario C: explicit override (e.g. ECC_HOOK_NODE).
    override = Override(
        path="/opt/real-node/bin/node",
        source="ECC_HOOK_NODE override",
    );
    default_rt = DefaultRuntime(binary="node");

    # Wire candidates into a small graph rooted at `root`.
    # Override is highest priority, then Host (if safe), then Default.
    root +>:Candidate(priority=10):+> override;
    root +>:Candidate(priority=5):+> node_host;
    root +>:Candidate(priority=5):+> omp_host;
    root +>:Candidate(priority=1):+> default_rt;

    # Resolve for each scenario by spawning a picker per host.
    picker = RuntimePicker();
    root spawn picker;
    print(
        f"[A:plain-node] chosen={picker.chosen} reason={picker.reason}"
    );

    picker_b = RuntimePicker();
    # Wire a fresh override so we can demonstrate it winning.
    root +>:Candidate(priority=20):+> Override(
        path="/opt/real-node/bin/node",
        source="ECC_HOOK_NODE override",
    );
    root spawn picker_b;
    print(
        f"[B:override]  chosen={picker_b.chosen} reason={picker_b.reason}"
    );

    picker_c = RuntimePicker();
    # Show the OMP host getting rejected by routing the picker to it
    # specifically: it should NOT pick omp_host.execPath.
    omp_host_only = Host(
        name="omp-only",
        release_name="node",
        bun_version="1.4.0",
        exec_path="/opt/omp/omp",
    );
    root +>:Candidate(priority=5):+> omp_host_only;
    root +>:Candidate(priority=1):+> DefaultRuntime(binary="node");
    root spawn picker_c;
    print(
        f"[C:omp-only]  chosen={picker_c.chosen} reason={picker_c.reason}"
    );
}