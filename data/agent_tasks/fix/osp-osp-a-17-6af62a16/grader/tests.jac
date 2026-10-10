"""Test annex for the bug tracker program.

Covers:
  1. The grouped-creation idiom `proj ++> (fresh := Ticket(...))` returns
     a node that is actually attached to the project (one edge, correct
     fields), so the "connect-and-grab" promise holds.
  2. Two distinct tickets filed via grouped creation both attach, so
     state built through the idiom survives into the graph normally.
  3. The `Triage` walker produces the expected per-ticket log line,
     using the live `available` field (so the OPEN/CLOSED branch is
     exercised for at least one ticket).
"""
import from main { Project, Ticket, Triage }

import io;
import from contextlib { redirect_stdout }


test "connect-and-grab binds the freshly created ticket" {
    root ++> Project(name="Compiler");
    proj = [root -->][0];

    # The promise: connect and capture in one expression.
    fresh = proj ++> (t := Ticket(title="Walker cycle guard hangs", priority="high"));

    # Exactly one edge from the project, leading to a Ticket with the
    # fields we just declared — no lookup required.
    assert len([proj -->]) == 1, f"expected 1 ticket attached, got {len([proj -->])}";
    attached = [proj -->][0];
    assert attached.title == "Walker cycle guard hangs",
        f"got title={attached.title}";
    assert attached.priority == "high", f"got priority={attached.priority}";
    assert attached.available is True, f"got available={attached.available}";

    # And the captured handle IS that node — `fresh` is not a separate,
    # detached copy.
    assert fresh is attached, "connect-and-grab returned a node that is not the attached ticket";
}


test "multiple tickets can be filed via grouped creation" {
    root ++> Project(name="Docs");
    proj = [root -->][0];

    proj ++> (a := Ticket(title="First", priority="high"));
    proj ++> (b := Ticket(title="Second", priority="low", available=False));

    # Two edges out of the project, two captured handles, both alive.
    assert len([proj -->]) == 2, f"expected 2 tickets, got {len([proj -->])}";
    assert a.title == "First", f"a.title={a.title}";
    assert b.title == "Second", f"b.title={b.title}";
    assert a.available is True, "defaults must apply when not overridden";
    assert b.available is False, "explicit False must override the default";
}


test "Triage walker prints project name and per-ticket status" {
    root ++> Project(name="Jac Compiler");
    proj = [root -->][0];

    proj ++> (fresh := Ticket(title="Walker cycle guard hangs", priority="high"));
    proj ++> (stale := Ticket(title="Typo in docs", priority="low", available=False));

    buf = io.StringIO();
    with redirect_stdout(buf) {
        root spawn Triage();
    }
    out = buf.getvalue();

    # Header line for the project node we entered.
    assert "Project: Jac Compiler" in out, f"missing project line: {out!r}";

    # The fresh, default-available ticket must log as OPEN.
    assert "[OPEN] Walker cycle guard hangs (priority=high)" in out,
        f"missing OPEN log for fresh ticket: {out!r}";

    # The stale ticket with available=False must log as CLOSED.
    assert "[CLOSED] Typo in docs (priority=low)" in out,
        f"missing CLOSED log for stale ticket: {out!r}";
}


test "Triage walker honours the live available flag on each ticket" {
    # Independent graph: exercise the OPEN branch with a single ticket
    # so we know the status string comes from here.available, not from
    # any incidental state shared between tests.
    root ++> Project(name="Solo");
    proj = [root -->][0];
    proj ++> (only := Ticket(title="Solo bug", priority="medium"));

    buf = io.StringIO();
    with redirect_stdout(buf) {
        root spawn Triage();
    }
    out = buf.getvalue();

    assert "[OPEN] Solo bug (priority=medium)" in out,
        f"expected OPEN line, got: {out!r}";
    assert "CLOSED" not in out, f"unexpected CLOSED in: {out!r}";
}
