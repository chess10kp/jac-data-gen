import from .extensions.walkers.alert_walkers { EmitAlert, AcknowledgeAlert, ListOpenAlerts }

test "regression: emit, acknowledge, list by hall" {
    root spawn EmitAlert(alert_id="r_a", subject="x", created_at="2026-02-01T08:00", severity="low", hall_id="h1");
    root spawn EmitAlert(alert_id="r_b", subject="y", created_at="2026-02-01T09:00", severity="high", hall_id="h2");
    root spawn AcknowledgeAlert(alert_id="r_b", reviewer_id="r1");
    w = root spawn ListOpenAlerts(hall_id="h1");
    got = [str(a["alert_id"]) for a in w.reports[-1]["open_alerts"]];
    assert got == ["r_a"];
    w2 = root spawn ListOpenAlerts();
    got2 = [str(a["alert_id"]) for a in w2.reports[-1]["open_alerts"]];
    assert "r_b" not in got2;
}
