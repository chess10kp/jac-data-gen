import uuid;
import from activities {
    Club, Event, Registration, Hosts, HasRegistration,
    create_club, create_event, approve_event, get_activities, signup_for_activity, unregister_from_activity
}

def run(w: Walker) -> any {
    return (root spawn w).reports[0];
}

def setup(t: str, cap: int) -> str {
    run(create_club(name="Chess " + t, description="board games", coordinator_id="coord-" + t));
    run(create_event(club_name="Chess " + t, name="Chess Night " + t, description="weekly games",
                     schedule="Fridays, 3:30 PM - 5:00 PM", max_participants=cap));
    run(approve_event(name="Chess Night " + t));
    return "Chess Night " + t;
}

def acts -> dict[str, any] {
    return dict(run(get_activities()));
}

test "clubs host events; only approved events are listed" {
    t = uuid.uuid4().hex[:8];
    c = dict(run(create_club(name="Art " + t, description="painting", coordinator_id="c1")));
    assert c["name"] == "Art " + t;
    assert dict(run(create_club(name="Art " + t, description="dup", coordinator_id="c2")))["status"] == 400;
    e = dict(run(create_event(club_name="Art " + t, name="Sketch " + t, description="draw", schedule="Mon", max_participants=5)));
    assert e["status"] == "pending";
    club = [x for x in [root -->[?:Club]] if x.name == "Art " + t][0];
    assert [x.name for x in [club ->:Hosts:->]] == ["Sketch " + t];
    assert "Sketch " + t not in acts();
    assert dict(run(approve_event(name="Sketch " + t)))["status"] == "approved";
    a = dict(acts()["Sketch " + t]);
    assert a["description"] == "draw" and a["schedule"] == "Mon" and a["max_participants"] == 5;
    assert a["participants"] == 0 and a["_id"] == e["id"];
    assert dict(run(create_event(club_name="Nope " + t, name="x", description="x", schedule="x", max_participants=1)))["status"] == 404;
}

test "signup counts participants and rejects duplicates" {
    t = uuid.uuid4().hex[:8];
    n = setup(t, 3);
    r = dict(run(signup_for_activity(activity_name=n, email="ann@school.edu")));
    assert r["message"] == "Signed up ann@school.edu for " + n;
    dup = dict(run(signup_for_activity(activity_name=n, email="ann@school.edu")));
    assert dup["status"] == 400 and dup["detail"] == "Student is already signed up";
    run(signup_for_activity(activity_name=n, email="bob@school.edu"));
    assert dict(acts()[n])["participants"] == 2;
    ev = [x for c in [root -->[?:Club]] for x in [c ->:Hosts:->] if x.name == n][0];
    assert sorted([x.student_id for x in [ev ->:HasRegistration:->]]) == ["ann@school.edu", "bob@school.edu"];
}

test "capacity is enforced" {
    t = uuid.uuid4().hex[:8];
    n = setup(t, 2);
    run(signup_for_activity(activity_name=n, email="a@s.edu"));
    run(signup_for_activity(activity_name=n, email="b@s.edu"));
    full = dict(run(signup_for_activity(activity_name=n, email="c@s.edu")));
    assert full["status"] == 400 and full["detail"] == "Activity is at maximum capacity";
    assert dict(acts()[n])["participants"] == 2;
}

test "unregister cancels and frees the seat" {
    t = uuid.uuid4().hex[:8];
    n = setup(t, 1);
    run(signup_for_activity(activity_name=n, email="a@s.edu"));
    u = dict(run(unregister_from_activity(activity_name=n, email="a@s.edu")));
    assert u["message"] == "Unregistered a@s.edu from " + n;
    assert dict(acts()[n])["participants"] == 0;
    ev = [x for c in [root -->[?:Club]] for x in [c ->:Hosts:->] if x.name == n][0];
    regs = [x for x in [ev ->:HasRegistration:->]];
    assert len(regs) == 1 and regs[0].status == "cancelled" and regs[0].cancelled_at is not None;
    again = dict(run(unregister_from_activity(activity_name=n, email="a@s.edu")));
    assert again["status"] == 400 and again["detail"] == "Student is not signed up for this activity";
    ok = dict(run(signup_for_activity(activity_name=n, email="b@s.edu")));
    assert ok["message"] == "Signed up b@s.edu for " + n;
    back = dict(run(signup_for_activity(activity_name=n, email="a@s.edu")));
    assert back["status"] == 400 and back["detail"] == "Activity is at maximum capacity";
}

test "re-signup after cancelling is allowed" {
    t = uuid.uuid4().hex[:8];
    n = setup(t, 5);
    run(signup_for_activity(activity_name=n, email="a@s.edu"));
    run(unregister_from_activity(activity_name=n, email="a@s.edu"));
    r = dict(run(signup_for_activity(activity_name=n, email="a@s.edu")));
    assert r["message"] == "Signed up a@s.edu for " + n;
    assert dict(acts()[n])["participants"] == 1;
}

test "unknown activity is a 404" {
    t = uuid.uuid4().hex[:8];
    a = dict(run(signup_for_activity(activity_name="Ghost " + t, email="a@s.edu")));
    assert a["status"] == 404 and a["detail"] == "Activity not found";
    b = dict(run(unregister_from_activity(activity_name="Ghost " + t, email="a@s.edu")));
    assert b["status"] == 404;
}
