"""Walkers that surface alerts, notify reviewers, and handle escalations."""


import from ..domain.nodes { Alert, Reviewer, WasteRecord }
walker :pub EmitAlert {
    has alert_id: str;
    has subject: str;
    has created_at: str;
    has body: str = "";
    has severity: str = "medium";
    has hall_id: str = "";
    has created: bool = False;

    can start with Root entry {
        alert = Alert(
            alert_id=self.alert_id,
            created_at=self.created_at,
            severity=self.severity,
            subject=self.subject,
            body=self.body,
            hall_id=self.hall_id
        );
        root ++> alert;
        self.created = True;
        report {"alert_id": self.alert_id, "created": self.created};
    }
}

walker :pub AcknowledgeAlert {
    has alert_id: str;
    has reviewer_id: str;
    has acknowledged: bool = False;

    can start with Root entry {
        visit [-->][?:Alert, alert_id == self.alert_id];
    }

    can mark with Alert entry {
        here.acknowledged = True;
        self.acknowledged = True;
    }

    can finish with Root exit {
        report {"alert_id": self.alert_id, "acknowledged": self.acknowledged};
    }
}

walker :pub ListOpenAlerts {
    has hall_id: str = "";
    has min_severity: str = "low";
    has alerts: list[dict[any, any]] = [];

    can start with Root entry {
        visit [-->][?:Alert, acknowledged == False];
    }

    can collect with Alert entry {
        if self.hall_id != "" and here.hall_id != self.hall_id {
            skip;
        }
        self.alerts.append({
            "alert_id": here.alert_id,
            "severity": here.severity,
            "subject": here.subject,
            "body": here.body,
            "created_at": here.created_at,
            "hall_id": here.hall_id
        });
    }

    can finish with Root exit {
        report {"open_alerts": self.alerts};
    }
}

walker :pub EscalateUnacknowledged {
    has older_than: str;
    has escalated: list[str] = [];

    can start with Root entry {
        visit [-->][?:Alert, acknowledged == False];
    }

    can inspect with Alert entry {
        if here.created_at < self.older_than {
            here.severity = "critical";
            self.escalated.append(here.alert_id);
        }
    }

    can finish with Root exit {
        report {"escalated": self.escalated, "count": len(self.escalated)};
    }
}

walker :pub AssignReviewerToHall {
    has reviewer_id: str;
    has hall_id: str;
    has assigned: bool = False;

    can start with Root entry {
        visit [-->][?:Reviewer, reviewer_id == self.reviewer_id];
    }

    can attach with Reviewer entry {
        if self.hall_id not in here.halls_managed {
            here.halls_managed.append(self.hall_id);
        }
        self.assigned = True;
    }

    can finish with Root exit {
        report {"reviewer_id": self.reviewer_id, "hall_id": self.hall_id, "assigned": self.assigned};
    }
}

walker :pub RegisterReviewer {
    has reviewer_id: str;
    has name: str;
    has role: str = "manager";
    has email: str = "";
    has created: bool = False;

    can start with Root entry {
        rv = Reviewer(
            reviewer_id=self.reviewer_id,
            name=self.name,
            role=self.role,
            email=self.email
        );
        root ++> rv;
        self.created = True;
        report {"reviewer_id": self.reviewer_id, "created": self.created};
    }
}

walker :pub NotifyHighCostRecord {
    has threshold_cost_usd: float = 50.0;
    has notifications: list[dict[any, any]] = [];

    can start with Root entry {
        visit [-->][?:WasteRecord];
    }

    can consider with WasteRecord entry {
        if here.total_cost_usd >= self.threshold_cost_usd {
            self.notifications.append({
                "record_id": here.record_id,
                "bin_id": here.bin_id,
                "cost_usd": here.total_cost_usd,
                "severity": here.severity
            });
        }
    }

    can finish with Root exit {
        report {"notifications": self.notifications};
    }
}

walker :pub ListHallsForReviewer {
    has reviewer_id: str;
    has halls: list[str] = [];

    can start with Root entry {
        visit [-->][?:Reviewer, reviewer_id == self.reviewer_id];
    }

    can fetch with Reviewer entry {
        self.halls = here.halls_managed;
    }

    can finish with Root exit {
        report {"reviewer_id": self.reviewer_id, "halls": self.halls};
    }
}
