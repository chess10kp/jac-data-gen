import from .extensions.walkers.alert_walkers { EmitAlert, AcknowledgeAlert, ListOpenAlerts, AddAlertNote, ListAlertNotes }
import from .extensions.domain.nodes { Alert, AlertNote }

def ensure_alert(aid: str) {
    if len([a for a in [root-->[?:Alert]] if a.alert_id == aid]) == 0 {
        root spawn EmitAlert(alert_id=aid, subject="bin overflow", created_at="2026-02-01T08:00", severity="high", hall_id="bursley");
    }
}

def add(aid: str, nid: str, who: str, txt: str, at: str) -> dict[str, any] {
    w = root spawn AddAlertNote(alert_id=aid, note_id=nid, author=who, text=txt, created_at=at);
    return w.reports[-1];
}

def notes(aid: str) -> dict[str, any] {
    w = root spawn ListAlertNotes(alert_id=aid);
    return w.reports[-1];
}

test "add notes and list them oldest first" {
    ensure_alert("n1");
    r = add("n1", "x2", "maria", "called facilities", "2026-02-01T10:00");
    assert r["added"] == True;
    assert r["note_count"] == 1;
    r = add("n1", "x1", "dev", "bin photographed", "2026-02-01T09:00");
    assert r["note_count"] == 2;
    out = notes("n1");
    assert out["found"] == True;
    got = [str(n["note_id"]) for n in out["notes"]];
    assert got == ["x1", "x2"];
    assert str(out["notes"][1]["author"]) == "maria";
    assert str(out["notes"][1]["text"]) == "called facilities";
}

test "notes live on the graph, attached to their alert" {
    ensure_alert("n2");
    add("n2", "y1", "sam", "first", "2026-02-02T09:00");
    a = [x for x in [root-->[?:Alert]] if x.alert_id == "n2"][0];
    attached = [n for n in [a -->][?:AlertNote]];
    assert len(attached) == 1;
    assert attached[0].note_id == "y1";
    assert len([n for n in [root-->][?:AlertNote]]) == 0;
}

test "notes are per-alert and duplicate note ids are ignored" {
    ensure_alert("n3");
    ensure_alert("n4");
    add("n3", "z1", "a", "one", "2026-02-03T09:00");
    dup = add("n3", "z1", "a", "one again", "2026-02-03T09:05");
    assert dup["added"] == False;
    assert dup["note_count"] == 1;
    add("n4", "z2", "b", "two", "2026-02-03T09:00");
    assert len(notes("n3")["notes"]) == 1;
    assert len(notes("n4")["notes"]) == 1;
}

test "unknown alert and blank text are rejected" {
    r = add("does-not-exist", "q1", "a", "hello", "2026-02-03T09:00");
    assert r["added"] == False;
    out = notes("does-not-exist");
    assert out["found"] == False;
    assert len(out["notes"]) == 0;
    ensure_alert("n5");
    r2 = add("n5", "q2", "a", "   ", "2026-02-03T09:00");
    assert r2["added"] == False;
}

test "regression: alert listing unaffected by notes" {
    ensure_alert("n6");
    add("n6", "w1", "a", "note", "2026-02-03T09:00");
    w = root spawn ListOpenAlerts(hall_id="bursley");
    got = [str(a["alert_id"]) for a in w.reports[-1]["open_alerts"]];
    assert "n6" in got;
    root spawn AcknowledgeAlert(alert_id="n6", reviewer_id="r1");
    w2 = root spawn ListOpenAlerts(hall_id="bursley");
    assert "n6" not in [str(a["alert_id"]) for a in w2.reports[-1]["open_alerts"]];
}
