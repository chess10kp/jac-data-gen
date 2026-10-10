import from .server { get_crisis_history, get_executives, get_system_metrics, initialize_graph }
import from .models { Crisis, Severity, Executive }

def seed_crises() {
    if len([root-->[?:Crisis]]) == 0 {
        root ++> Crisis(id="c1", severity=Severity.INFO, message="disk at 70%", triggered_at="2026-03-01T10:00:00");
        root ++> Crisis(id="c2", severity=Severity.CRITICAL, message="db down", triggered_at="2026-03-03T09:00:00");
        root ++> Crisis(id="c3", severity=Severity.WARNING, message="latency spike", triggered_at="2026-03-02T12:30:00");
        root ++> Crisis(id="c4", severity=Severity.HIGH, message="auth errors", triggered_at="2026-03-04T08:15:00");
    }
}

test "history is newest first" {
    seed_crises();
    hist = get_crisis_history();
    ids = [c.id for c in hist];
    assert ids == ["c4", "c2", "c3", "c1"];
}

test "history respects limit" {
    seed_crises();
    hist = get_crisis_history(limit=2);
    assert [c.id for c in hist] == ["c4", "c2"];
    assert len(get_crisis_history(limit=0)) == 0;
}

test "history filters by minimum severity" {
    seed_crises();
    assert [c.id for c in get_crisis_history(min_severity="HIGH")] == ["c4", "c2"];
    assert [c.id for c in get_crisis_history(min_severity="warning")] == ["c4", "c2", "c3"];
    assert len(get_crisis_history(min_severity="CRITICAL")) == 1;
}

test "regression: seeding and metrics still work" {
    initialize_graph();
    initialize_graph();
    assert len(get_executives()) == 6;
    m = get_system_metrics();
    assert m.net_latency >= 0;
}
