"""Walkers that write and query audit trail entries for compliance."""

node AuditEvent {
    has event_id: str;
    has occurred_at: str;
    has action: str;
    has actor: str = "system";
    has target_id: str = "";
    has target_type: str = "";
    has details: str = "";
    has ip_address: str = "";
    has session_id: str = "";
}

edge LoggedFor: any --> any {
    has logged_at: str;
    has source: str = "api";
}

walker :pub RecordAuditEvent {
    has event_id: str;
    has occurred_at: str;
    has action: str;
    has actor: str = "system";
    has target_id: str = "";
    has target_type: str = "";
    has details: str = "";
    has created: bool = False;

    can start with Root entry {
        evt = AuditEvent(
            event_id=self.event_id,
            occurred_at=self.occurred_at,
            actor=self.actor,
            action=self.action,
            target_id=self.target_id,
            target_type=self.target_type,
            details=self.details
        );
        root ++> evt;
        self.created = True;
        report {"event_id": self.event_id, "created": self.created};
    }
}

walker :pub QueryAuditLog {
    has actor_filter: str = "";
    has action_filter: str = "";
    has target_type_filter: str = "";
    has since: str = "";
    has until: str = "";
    has entries: list[dict[any, any]] = [];

    can start with Root entry {
        visit [-->][?:AuditEvent];
    }

    can collect with AuditEvent entry {
        if self.actor_filter != "" and here.actor != self.actor_filter {
            skip;
        }
        if self.action_filter != "" and here.action != self.action_filter {
            skip;
        }
        if self.target_type_filter != "" and here.target_type != self.target_type_filter {
            skip;
        }
        if self.since != "" and here.occurred_at < self.since {
            skip;
        }
        if self.until != "" and here.occurred_at > self.until {
            skip;
        }
        self.entries.append({
            "event_id": here.event_id,
            "occurred_at": here.occurred_at,
            "actor": here.actor,
            "action": here.action,
            "target_id": here.target_id,
            "target_type": here.target_type,
            "details": here.details
        });
    }

    can finish with Root exit {
        self.entries.sort(key=lambda (e: dict[any, any]) -> str { return e["occurred_at"]; });
        report {"entries": self.entries, "count": len(self.entries)};
    }
}

walker :pub AuditTrailForRecord {
    has target_id: str;
    has events: list[dict[any, any]] = [];

    can start with Root entry {
        visit [-->][?:AuditEvent, target_id == self.target_id];
    }

    can collect with AuditEvent entry {
        self.events.append({
            "event_id": here.event_id,
            "occurred_at": here.occurred_at,
            "actor": here.actor,
            "action": here.action,
            "details": here.details
        });
    }

    can finish with Root exit {
        self.events.sort(key=lambda (e: dict[any, any]) -> str { return e["occurred_at"]; });
        report {"target_id": self.target_id, "events": self.events};
    }
}

walker :pub ActorActivitySummary {
    has actor: str;
    has since: str = "";
    has action_counts: dict[str, int] = {};
    has total: int = 0;

    can start with Root entry {
        visit [-->][?:AuditEvent, actor == self.actor];
    }

    can tally with AuditEvent entry {
        if self.since != "" and here.occurred_at < self.since {
            skip;
        }
        prev = self.action_counts.get(here.action, 0);
        self.action_counts[here.action] = prev + 1;
        self.total += 1;
    }

    can finish with Root exit {
        report {
            "actor": self.actor,
            "total_actions": self.total,
            "actions": self.action_counts
        };
    }
}

walker :pub PurgeOldAuditEvents {
    has older_than: str;
    has confirm_token: str;
    has removed: int = 0;

    can start with Root entry {
        if self.confirm_token != "AUDIT_PURGE_CONFIRMED" {
            report {"removed": 0, "confirmed": False};
            disengage;
        }
        for evt in [root -->][?:AuditEvent] {
            if evt.occurred_at < self.older_than {
                root del--> evt;
                self.removed += 1;
            }
        }
        report {"removed": self.removed, "confirmed": True};
    }
}
