import uuid;
import from reminders {
    User, Medication, Notification, Takes, Notified, is_time_right_format,
    register_user, add_medication, get_medications, get_medications_ready_for_notifications,
    delete_medication, record_notification, mark_taken, get_taken_notifications_for_time_period,
    get_notification_for_current_day, get_not_taken_notifications_for_current_day
}

def run(w: Walker) -> any {
    return (root spawn w).reports[0];
}

def new_user -> int {
    tg = uuid.uuid4().int % 1000000000;
    r = dict(run(register_user(username="u" + str(tg), tg_user_id=tg, tg_chat_id=tg)));
    assert r["ok"] == True;
    return tg;
}

def med(tg: int, name: str, at: str) -> str {
    return dict(run(add_medication(tg_user_id=tg, name=name, notification_time=at)))["id"];
}

test "time format rules" {
    assert is_time_right_format("14:55");
    assert is_time_right_format("05:00");
    assert not is_time_right_format("16:0");
    assert not is_time_right_format("04:55");
    assert not is_time_right_format("20:00");
    assert not is_time_right_format("12:03");
    assert not is_time_right_format("noon");
}

test "register is unique by username" {
    tg = new_user();
    dup = dict(run(register_user(username="u" + str(tg), tg_user_id=1, tg_chat_id=1)));
    assert "error" in dup;
    assert len([u for u in [root -->[?:User]] if u.username == "u" + str(tg)]) == 1;
}

test "new medication hangs off its user" {
    tg = new_user();
    m = dict(run(add_medication(tg_user_id=tg, name="omega-3", notification_time="14:55")));
    assert m["name"] == "omega-3" and m["notification_time"] == "14:55" and m["deleted"] == False;
    u = [x for x in [root -->[?:User]] if x.tg_user_id == tg][0];
    assert [x.name for x in [u ->:Takes:->]] == ["omega-3"];
    assert "error" in dict(run(add_medication(tg_user_id=tg, name="bad", notification_time="23:00")));
    assert "error" in dict(run(add_medication(tg_user_id=-5, name="x", notification_time="10:00")));
    assert len([x for x in [u ->:Takes:->]]) == 1;
}

test "medications are per user, sorted by time, soft-deleted ones hidden" {
    a = new_user();
    b = new_user();
    med(a, "c", "18:00");
    first = med(a, "a", "06:30");
    med(a, "b", "12:15");
    med(b, "other", "07:00");
    names = [m["name"] for m in run(get_medications(tg_user_id=a))];
    assert names == ["a", "b", "c"];
    assert run(delete_medication(medication_id=first)) == True;
    assert [m["name"] for m in run(get_medications(tg_user_id=a))] == ["b", "c"];
    assert [m["name"] for m in run(get_medications(tg_user_id=b))] == ["other"];
    u = [x for x in [root -->[?:User]] if x.tg_user_id == a][0];
    assert len([x for x in [u ->:Takes:->]]) == 3;
    assert run(delete_medication(medication_id="nope")) == False;
}

test "ready for notifications compares notification_time to the clock" {
    a = new_user();
    med(a, "early", "08:00");
    med(a, "noon", "12:00");
    gone = med(a, "gone", "07:00");
    med(a, "late", "19:00");
    run(delete_medication(medication_id=gone));
    assert [m["name"] for m in run(get_medications_ready_for_notifications(tg_user_id=a, at="12:00"))] == ["early", "noon"];
    assert len(list(run(get_medications_ready_for_notifications(tg_user_id=a, at="05:00")))) == 0;
}

test "notifications: record, taken window, current day lookups" {
    a = new_user();
    b = new_user();
    m1 = med(a, "vit-d", "09:00");
    m2 = med(a, "iron", "10:00");
    mb = med(b, "zinc", "09:00");
    day = "19" + str(10 + uuid.uuid4().int % 89) + "-03-0";
    n1 = dict(run(record_notification(medication_id=m1, sent_at=day + "1T09:00:00")));
    n2 = dict(run(record_notification(medication_id=m1, sent_at=day + "2T09:00:00")));
    n3 = dict(run(record_notification(medication_id=m2, sent_at=day + "3T10:00:00")));
    nb = dict(run(record_notification(medication_id=mb, sent_at=day + "2T09:00:00")));
    assert n1["was_taken"] == False and n1["medication"] == "vit-d";
    mnode = [m for m in [[x for x in [root -->[?:User]] if x.tg_user_id == a][0] ->:Takes:->] if m.name == "vit-d"][0];
    assert len([x for x in [mnode ->:Notified:->]]) == 2;
    assert run(mark_taken(notification_id=n3["id"])) == True;
    assert run(mark_taken(notification_id=n1["id"])) == True;
    assert run(mark_taken(notification_id=nb["id"])) == True;
    assert run(mark_taken(notification_id="nope")) == False;
    taken = [n["id"] for n in run(get_taken_notifications_for_time_period(tg_user_id=a, start=day + "1T00:00:00", end=day + "3T23:59:59"))];
    assert taken == [n1["id"], n3["id"]];
    narrow = [n["id"] for n in run(get_taken_notifications_for_time_period(tg_user_id=a, start=day + "2T00:00:00", end=day + "3T23:59:59"))];
    assert narrow == [n3["id"]];
    today = dict(run(get_notification_for_current_day(medication_id=m1, day=day + "2")));
    assert today["id"] == n2["id"];
    assert run(get_notification_for_current_day(medication_id=m1, day=day + "4")) is None;
    open_ids = [n["id"] for n in run(get_not_taken_notifications_for_current_day(day=day + "2"))];
    assert n2["id"] in open_ids and nb["id"] not in open_ids and n1["id"] not in open_ids;
}
