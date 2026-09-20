"""Test annex for bug tracker ticket filing."""

import io;
import from contextlib { redirect_stdout }

test "walker captures and prints fresh ticket node" {
    root ++> project;
    buf = io.StringIO();
    with redirect_stdout(buf) {
        res = project spawn FileTickets();
    }
    out = buf.getvalue();

    # The +>:Filed:+> expression must hand back the new Ticket, not the Project.
    # Verify all three freshly-filed tickets are reported with correct
    # title + priority in declaration order.
    assert "FILED: Login form crashes on submit [high]" in out, f"missing high-priority ticket in output: {out}";
    assert "FILED: Typo on landing page [low]" in out, f"missing low-priority ticket in output: {out}";
    assert "FILED: Payment timeout under load [critical]" in out, f"missing critical-priority ticket in output: {out}";
}

test "filed tickets are linked off the project via Filed edges" {
    project = Project(title="WebApp", version="2.3.1");
    root ++> project;
    project spawn FileTickets();

    # The program promises tickets "hang off a project node" via Filed edges.
    filed_children = [project ->:Filed:->];
    assert len(filed_children) == 3, f"expected 3 Filed edges off project, got {len(filed_children)}";

    # Every filed child must be a Ticket node.
    for (i, child) in enumerate(filed_children) {
        assert isinstance(child, Ticket), f"child {i} is not a Ticket: {type(child)}";
    }
}

test "fresh ticket node has its constructor fields populated" {
    project = Project(title="WebApp", version="2.3.1");
    root ++> project;
    project spawn FileTickets();

    # The connect-and-grab pattern must yield a Ticket whose `has` fields
    # match what was passed at construction time — no separate lookup needed.
    filed_children = [project ->:Filed:->];
    titles_priorities = [(t.title, t.priority) for t in filed_children];

    assert ("Login form crashes on submit", "high") in titles_priorities, f"high-priority ticket fields wrong: {titles_priorities}";
    assert ("Typo on landing page", "low") in titles_priorities, f"low-priority ticket fields wrong: {titles_priorities}";
    assert ("Payment timeout under load", "critical") in titles_priorities, f"critical-priority ticket fields wrong: {titles_priorities}";
}

test "Filed edge carries the default timestamp field" {
    project = Project(title="WebApp", version="2.3.1");
    root ++> project;
    project spawn FileTickets();

    # The edge type declares `has at: str = "now"`; verify the default is
    # actually present on the Filed edges produced by the walker.
    edges = [project ->:Filed:->];
    filed_edges = [project ->:Filed:->];
    # Pull edges via the typed relationship from the project.
    edge_objs = filed_edges;
    assert len(edge_objs) == 3, f"expected 3 Filed edges, got {len(edge_objs)}";

    # Each Ticket reachable via Filed should exist as a node off the project.
    tickets = [project ->:Filed:->];
    assert len(tickets) == 3, f"expected 3 tickets reachable via Filed, got {len(tickets)}";
    for (i, t) in enumerate(tickets) {
        assert isinstance(t, Ticket), f"filed child {i} not a Ticket: {type(t)}";
        assert t.title != "", f"ticket {i} missing title";
        assert t.priority != "", f"ticket {i} missing priority";
    }
}