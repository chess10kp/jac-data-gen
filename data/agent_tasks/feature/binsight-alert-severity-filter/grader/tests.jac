import from .extensions.walkers.alert_walkers { EmitAlert, AcknowledgeAlert, ListOpenAlerts }
import from .extensions.domain.nodes { Alert }

def seed() {
    if len([root-->[?:Alert]]) == 0 {
        root spawn EmitAlert(alert_id="a_low", subject="bin 3 slightly full", created_at="2026-02-01T08:00", severity="low", hall_id="bursley");
        root spawn EmitAlert(alert_id="a_med", subject="cost over budget", created_at="2026-02-01T09:00", severity="medium", hall_id="bursley");
        root spawn EmitAlert(alert_id="a_high", subject="protein waste spike", created_at="2026-02-01T10:00", severity="high", hall_id="markley");
        root spawn EmitAlert(alert_id="a_crit", subject="scale offline", created_at="2026-02-01T11:00", severity="critical", hall_id="bursley");
        root spawn EmitAlert(alert_id="a_crit_ack", subject="old outage", created_at="2026-01-01T11:00", severity="critical", hall_id="bursley");
        root spawn AcknowledgeAlert(alert_id="a_crit_ack", reviewer_id="r1");
    }
}

def ids(min_sev: str, hall: str = "") -> list[str] {
    w = root spawn ListOpenAlerts(min_severity=min_sev, hall_id=hall);
    return [str(a["alert_id"]) for a in w.reports[-1]["open_alerts"]];
}

test "default lists every open alert, most severe first" {
    seed();
    got = ids("low");
    assert len(got) == 4;
    assert got[0] == "a_crit";
    assert got[1] == "a_high";
    assert got[2] == "a_med";
    assert got[3] == "a_low";
}

test "min_severity filters out lower severities" {
    seed();
    assert sorted(ids("high")) == ["a_crit", "a_high"];
    assert ids("critical") == ["a_crit"];
    assert sorted(ids("medium")) == ["a_crit", "a_high", "a_med"];
}

test "min_severity is case-insensitive and composes with hall filter" {
    seed();
    assert sorted(ids("HIGH", "bursley")) == ["a_crit"];
    assert sorted(ids("Medium", "bursley")) == ["a_crit", "a_med"];
}

test "regression: acknowledged alerts stay hidden and hall filter works" {
    seed();
    assert "a_crit_ack" not in ids("low");
    assert sorted(ids("low", "markley")) == ["a_high"];
}
