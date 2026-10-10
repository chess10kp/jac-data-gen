import from main { Agent, AssignedTo, Attempt, BoardInspector, Decomposes, DependsOn, Objective, Produces, Task }
import io;
import from contextlib { redirect_stdout }

test "inspects tasks and dependencies" {
    obja = Objective(title="Board", goal="Shared truth");
    t_pending = Task(title="Pending", state="pending");
    t_blocked = Task(title="Blocked", state="ready");

    root +>:Decomposes:+> obja;
    obja +>:Decomposes:+> t_blocked;
    obja +>:Decomposes:+> t_pending;
    t_blocked +>:DependsOn:+> t_pending;

    buf = io.StringIO();
    with redirect_stdout(buf) {
        res = root spawn BoardInspector();
    }
    out = buf.getvalue();

    assert res.objective_count == 1, f"got {res.objective_count}";
    assert res.task_count == 2, f"got {res.task_count}";
    assert res.ready_count == 1, f"got {res.ready_count}";

    root_children = len([root-->]);
    objective_children = len([obja ->:Decomposes:->]);
    assert root_children == 1, f"got {root_children}";
    assert objective_children == 2, f"got {objective_children}";
    assert t_blocked in [obja ->:Decomposes:->], f"missing blocked task";
    assert t_pending in [t_blocked ->:DependsOn:->], f"missing dependency";
    assert "[RUNNABLE] Pending" in out, f"missing runnable output: {out}";
    assert "[BLOCKED]  Blocked" in out, f"missing blocked output: {out}";
}

test "preserves context evidence assignments and attempts" {
    obja = Objective(title="Projection", goal="Read board truth");
    task = Task(title="Render UI", state="ready", context="bun test", evidence="build a2", attempt_count=2);
    agent = Agent(name="aurora", role="implementer");
    attempt = Attempt(note="web build passed", outcome="success");

    root +>:Decomposes:+> obja;
    obja +>:Decomposes:+> task;
    task +>:AssignedTo:+> agent;
    task +>:Produces:+> attempt;

    buf = io.StringIO();
    with redirect_stdout(buf) {
        res = root spawn BoardInspector();
    }
    out = buf.getvalue();

    assert task.state == "ready", f"got {task.state}";
    assert task.attempt_count == 2, f"got {task.attempt_count}";
    assert agent.name == "aurora", f"got {agent.name}";
    assert agent in [task ->:AssignedTo:->], f"missing assignment";
    assert attempt in [task ->:Produces:->], f"missing attempt";
    assert "context : bun test" in out, f"missing context: {out}";
    assert "evidence: build a2" in out, f"missing evidence: {out}";
    assert "[ATTEMPT OK ] web build passed" in out, f"missing attempt: {out}";
    assert res.ready_count == 1, f"got {res.ready_count}";
}

test "uses safe task and attempt defaults" {
    obja = Objective(title="Defaults", goal="Durable state");
    task = Task(title="Unstarted");
    attempt = Attempt(note="pending review");

    root +>:Decomposes:+> obja;
    obja +>:Decomposes:+> task;
    task +>:Produces:+> attempt;

    assert task.state == "pending", f"got {task.state}";
    assert task.context == "", f"got {task.context}";
    assert task.evidence == "", f"got {task.evidence}";
    assert task.attempt_count == 0, f"got {task.attempt_count}";
    assert attempt.outcome == "unknown", f"got {attempt.outcome}";

    buf = io.StringIO();
    with redirect_stdout(buf) {
        res = root spawn BoardInspector();
    }
    out = buf.getvalue();

    assert res.objective_count == 1, f"got {res.objective_count}";
    assert res.task_count == 1, f"got {res.task_count}";
    assert res.ready_count == 1, f"got {res.ready_count}";
    assert res.cycle_found == False, f"got {res.cycle_found}";
    assert "[RUNNABLE] Unstarted (state=pending, attempts=0)" in out, f"missing default output: {out}";
    assert "[ATTEMPT BAD] pending review" in out, f"missing unknown attempt output: {out}";
}
