"""Medication reminder store (Telegram bot backend) as a graph.

Beanie `User`, `Medication`, `Notification` documents become nodes; the
`Link[User]` / `Link[Medication]` references become edges
User -[Takes]-> Medication -[Notified]-> Notification. The classmethod queries
become walkers. Times are "HH:MM" strings, timestamps ISO-8601 strings.
"""

import datetime;

node User {
    has username: str;
    has tg_user_id: int;
    has tg_chat_id: int;
}

node Medication {
    has name: str;
    has notification_time: str;
    has deleted: bool = False;

    def view -> dict[str, any] {
        return {"id": jid(self), "name": self.name, "notification_time": self.notification_time,
                "deleted": self.deleted};
    }
}

node Notification {
    has sent_at: str;
    has was_taken: bool = False;

    def view -> dict[str, any] {
        med = [self <-:Notified:<-][0];
        return {"id": jid(self), "medication": med.name, "medication_id": jid(med),
                "sent_at": self.sent_at, "was_taken": self.was_taken};
    }
}

edge Takes: User --> Medication {}
edge Notified: Medication --> Notification {}

"""HH:MM, two-digit minutes, hour within 05..19, minutes divisible by 5."""
def is_time_right_format(time_string: str) -> bool {
    try {
        t = datetime.datetime.strptime(time_string, "%H:%M").time();
    } except ValueError {
        return False;
    }
    if len(time_string.split(":")[1]) != 2 {
        return False;
    }
    if t.hour < 5 or t.hour > 19 {
        return False;
    }
    return t.minute % 5 == 0;
}

def find_user(tg_user_id: int) -> User | None {
    for u in [root -->[?:User]] {
        if u.tg_user_id == tg_user_id {
            return u;
        }
    }
    return None;
}

def all_medications -> list[Medication] {
    return [m for u in [root -->[?:User]] for m in [u ->:Takes:->]];
}

def all_notifications -> list[Notification] {
    return [n for m in all_medications() for n in [m ->:Notified:->]];
}

def active_medications(u: User) -> list[Medication] {
    meds = [m for m in [u ->:Takes:->] if not m.deleted];
    return sorted(meds, key=lambda (m: Medication) -> str { return m.notification_time; });
}

walker register_user {
    has username: str;
    has tg_user_id: int;
    has tg_chat_id: int;

    can register with Root entry {
        if any(u.username == self.username for u in [-->[?:User]]) {
            report {"error": "username taken"};
            return;
        }
        here ++> User(username=self.username, tg_user_id=self.tg_user_id, tg_chat_id=self.tg_chat_id);
        report {"ok": True};
    }
}

walker add_medication {
    has tg_user_id: int;
    has name: str;
    has notification_time: str;

    can add with Root entry {
        u = find_user(self.tg_user_id);
        if u is None {
            report {"error": "unknown user"};
            return;
        }
        if not is_time_right_format(self.notification_time) {
            report {"error": "bad time"};
            return;
        }
        m = Medication(name=self.name, notification_time=self.notification_time);
        u +>:Takes:+> m;
        report m.view();
    }
}

walker get_medications {
    has tg_user_id: int;

    can list_meds with Root entry {
        u = find_user(self.tg_user_id);
        report [m.view() for m in active_medications(u)] if u else [];
    }
}

walker get_medications_ready_for_notifications {
    has tg_user_id: int;
    has at: str;

    can due with Root entry {
        u = find_user(self.tg_user_id);
        meds = active_medications(u) if u else [];
        report [m.view() for m in meds if m.notification_time <= self.at];
    }
}

"""Soft delete: the document is kept, only `deleted` is set."""
walker delete_medication {
    has medication_id: str;

    can remove with Root entry {
        for m in all_medications() {
            if jid(m) == self.medication_id {
                m.deleted = True;
                report True;
                return;
            }
        }
        report False;
    }
}

walker record_notification {
    has medication_id: str;
    has sent_at: str;
    has was_taken: bool = False;

    can record with Root entry {
        for m in all_medications() {
            if jid(m) == self.medication_id {
                n = Notification(sent_at=self.sent_at, was_taken=self.was_taken);
                m +>:Notified:+> n;
                report n.view();
                return;
            }
        }
        report None;
    }
}

walker mark_taken {
    has notification_id: str;

    can confirm with Root entry {
        for n in all_notifications() {
            if jid(n) == self.notification_id {
                n.was_taken = True;
                report True;
                return;
            }
        }
        report False;
    }
}

walker get_taken_notifications_for_time_period {
    has tg_user_id: int;
    has start: str;
    has end: str;

    can query with Root entry {
        u = find_user(self.tg_user_id);
        found: list[Notification] = [];
        if u {
            for m in [u ->:Takes:->] {
                found.extend([n for n in [m ->:Notified:->]
                              if n.was_taken and self.start <= n.sent_at and n.sent_at <= self.end]);
            }
        }
        report [n.view() for n in sorted(found, key=lambda (n: Notification) -> str { return n.sent_at; })];
    }
}

walker get_notification_for_current_day {
    has medication_id: str;
    has day: str;

    can query with Root entry {
        for m in all_medications() {
            if jid(m) == self.medication_id {
                for n in [m ->:Notified:->] {
                    if n.sent_at[:10] == self.day {
                        report n.view();
                        return;
                    }
                }
            }
        }
        report None;
    }
}

walker get_not_taken_notifications_for_current_day {
    has day: str;

    can query with Root entry {
        report [n.view() for n in all_notifications() if not n.was_taken and n.sent_at[:10] == self.day];
    }
}
