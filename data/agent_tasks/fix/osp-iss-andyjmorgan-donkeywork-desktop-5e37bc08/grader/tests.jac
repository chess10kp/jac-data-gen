import from main { AttachedTo, Contains, PtyProcess, Runs, SessionRevoker, TerminalClient, TerminalSession }
import io;
import from contextlib { redirect_stdout }

test "revokes the full terminal dependency chain" {
    session = TerminalSession(
        title="browser-terminal",
        year=2024,
        account="fixed-terminal",
        epoch=7,
        mode="desktop"
    );
    pty = PtyProcess(
        title="linux-pty",
        year=2024,
        process_id=4102,
        process_group=4102,
        width=3840,
        height=2160
    );
    client = TerminalClient(
        title="xterm-client",
        year=2024,
        client_id="browser-17"
    );

    root +>:Contains(label="authorized-session"):+> session;
    session +>:Runs(epoch=7):+> pty;
    pty +>:AttachedTo(terminal="browser"):+> client;

    buf = io.StringIO();
    with redirect_stdout(buf) {
        res = root spawn SessionRevoker();
    }
    out = buf.getvalue();

    assert len([root ->:Contains:->]) == 1, f"unexpected root session count";
    assert len([session ->:Runs:->]) == 1, f"unexpected PTY edge count";
    assert len([pty ->:AttachedTo:->]) == 1, f"unexpected client edge count";
    assert session.available == False, f"session available={session.available}";
    assert pty.available == False, f"pty available={pty.available}";
    assert client.available == False, f"client available={client.available}";
    assert res.invalidated == 3, f"invalidated={res.invalidated}";
    assert "revoked session browser-terminal, epoch 7" in out, f"missing session revoke output: {out}";
    assert "stopped PTY group 4102" in out, f"missing PTY stop output: {out}";
    assert "disconnected client browser-17" in out, f"missing client disconnect output: {out}";
}

test "fails closed when the session has no Runs edge" {
    session = TerminalSession(title="orphan-session", epoch=3);
    pty = PtyProcess(title="unreached-pty", process_group=9001);
    client = TerminalClient(title="unreached-client", client_id="browser-2");

    root +>:Contains(label="authorized-session"):+> session;
    pty +>:AttachedTo(terminal="browser"):+> client;

    buf = io.StringIO();
    with redirect_stdout(buf) {
        res = root spawn SessionRevoker();
    }
    out = buf.getvalue();

    assert len([session ->:Runs:->]) == 0, f"unexpected Runs edge count";
    assert session.available == False, f"session available={session.available}";
    assert pty.available == True, f"unreached PTY available={pty.available}";
    assert client.available == True, f"unreached client available={client.available}";
    assert res.invalidated == 1, f"invalidated={res.invalidated}";
    assert "revoked session orphan-session, epoch 3" in out, f"missing session output: {out}";
    assert "stopped PTY" not in out, f"unexpected PTY output: {out}";
    assert "disconnected client" not in out, f"unexpected client output: {out}";
}

test "stops at the configured depth limit" {
    session = TerminalSession(title="bounded-session", epoch=5);
    pty = PtyProcess(title="bounded-pty", process_group=7002);
    client = TerminalClient(title="bounded-client", client_id="browser-3");

    root +>:Contains(label="authorized-session"):+> session;
    session +>:Runs(epoch=5):+> pty;
    pty +>:AttachedTo(terminal="browser"):+> client;

    buf = io.StringIO();
    with redirect_stdout(buf) {
        res = root spawn SessionRevoker(max_depth=1);
    }
    out = buf.getvalue();

    assert session.available == False, f"session available={session.available}";
    assert pty.available == True, f"pty available={pty.available}";
    assert client.available == True, f"client available={client.available}";
    assert res.invalidated == 1, f"invalidated={res.invalidated}";
    assert "cycle or depth limit reached at PTY" in out, f"missing depth-limit output: {out}";
}
