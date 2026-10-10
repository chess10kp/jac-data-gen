import from main { HookSpec, HostRuntime, Hosts, Respawns, SessionStartExecutor, Triggers }
import io;
import from contextlib { redirect_stdout }

test "normal Node runtime executes the hook once" {
    hook = HookSpec(title="ecc-session-start");
    host = HostRuntime(
        title="node-host",
        exec_path="/usr/local/bin/node",
        release_name="node"
    );
    root +>:Hosts:+> host;
    host +>:Triggers:+> hook;

    buf = io.StringIO();
    with redirect_stdout(buf) {
        res = root spawn SessionStartExecutor();
    }
    out = buf.getvalue();

    assert res.launches == 1, f"got {res.launches}";
    assert res.current_runtime == "/usr/local/bin/node", f"got {res.current_runtime}";
    assert "[OK] hook completed once" in out, f"missing completion marker: {out}";
}

test "compiled OMP selects Node instead of process execPath" {
    hook = HookSpec(title="ecc-session-start");
    parent = HostRuntime(
        title="omp-parent",
        exec_path="/usr/bin/omp",
        release_name="node",
        bun_version="1.4.0"
    );
    child = HostRuntime(
        title="omp-child",
        exec_path="/usr/bin/omp",
        release_name="node",
        bun_version="1.4.0"
    );
    root +>:Hosts:+> parent;
    parent +>:Triggers:+> hook;
    hook +>:Respawns(reason="resume"):+> child;
    child +>:Triggers:+> hook;

    buf = io.StringIO();
    with redirect_stdout(buf) {
        res = root spawn SessionStartExecutor();
    }
    out = buf.getvalue();

    assert res.launches == 1, f"got {res.launches}";
    assert res.current_runtime == "node", f"got {res.current_runtime}";
    assert "[OK] hook completed once under node" in out, f"missing completion marker: {out}";
    assert "[CYCLE]" not in out, f"unexpected recursion: {out}";
}

test "ECC_HOOK_NODE override is used for compiled OMP" {
    hook = HookSpec(title="ecc-session-start");
    host = HostRuntime(
        title="omp-override",
        exec_path="/usr/bin/omp",
        release_name="node",
        bun_version="1.4.0",
        hook_node_override="/opt/node/bin/node"
    );
    root +>:Hosts:+> host;
    host +>:Triggers:+> hook;

    buf = io.StringIO();
    with redirect_stdout(buf) {
        res = root spawn SessionStartExecutor();
    }
    out = buf.getvalue();

    assert res.launches == 1, f"got {res.launches}";
    assert res.current_runtime == "/opt/node/bin/node", f"got {res.current_runtime}";
    assert "[OK] hook completed once under /opt/node/bin/node" in out, f"missing completion marker: {out}";
}

test "naive OMP execPath exposes recursive respawn" {
    hook = HookSpec(title="ecc-session-start");
    parent = HostRuntime(
        title="omp-parent",
        exec_path="/usr/bin/omp",
        release_name="node",
        bun_version="1.4.0",
        use_exec_path_naively=True
    );
    child = HostRuntime(
        title="omp-child",
        exec_path="/usr/bin/omp",
        release_name="node",
        bun_version="1.4.0",
        use_exec_path_naively=True
    );
    root +>:Hosts:+> parent;
    parent +>:Triggers:+> hook;
    hook +>:Respawns(reason="resume"):+> child;
    child +>:Triggers:+> hook;

    buf = io.StringIO();
    with redirect_stdout(buf) {
        res = root spawn SessionStartExecutor(max_depth=5);
    }
    out = buf.getvalue();

    assert res.launches == 1, f"got {res.launches}";
    assert res.current_runtime == "/usr/bin/omp", f"got {res.current_runtime}";
    assert "[CYCLE]" in out, f"missing cycle marker: {out}";
}
