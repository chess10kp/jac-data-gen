"""AppealTracker walker — monitors appeal deadlines and auto-escalates.

Walks all active disputes and their appeals, checking:
1. Whether filing deadlines are approaching (warns at 30 days)
2. Whether deadlines have passed (auto-escalates if possible)
3. Whether decisions have come in and need follow-up
"""

import from graph.nodes.claim { Claim }
import from graph.nodes.line_item { LineItem }
import from graph.nodes.patient { Patient }
import from graph.nodes.dispute { Dispute }
import from graph.nodes.appeal { Appeal }
import from graph.nodes.notification { Notification }

import from datetime { datetime, timedelta }
import from uuid { uuid4 }

glob DEADLINE_WARNING_DAYS = 30;

walker AppealTracker {
    has today: any = None;
    has patient_name: str = "";


    can start with Patient entry {
        self.today = datetime.utcnow().strftime("%Y-%m-%d");
        self.patient_name = here.name;
        visit [-->];
    }

    can check_claim_disputes with Claim entry {
        visit [-->];
    }

    can check_line_item_disputes with LineItem entry {
        visit [-->];
    }

    can track_dispute with Dispute entry {
        if here.status not in ["OPEN", "IN_PROGRESS", "APPEALED"] {
            disengage;
        }

        # Check deadline proximity
        if here.deadline != "" {
            try {
                deadline_dt = datetime.strptime(here.deadline, "%Y-%m-%d");
                today_dt = datetime.strptime(self.today, "%Y-%m-%d");
                days_remaining = (deadline_dt - today_dt).days;

                if days_remaining < 0 {
                    # Deadline PASSED — escalate
                    here.status = "ESCALATED";
                    print(
                        f"[AppealTracker] DEADLINE PASSED for dispute {here.dispute_id} "
                        f"(was {here.deadline})"
                    );
                    notif = Notification(
                        notification_id=str(uuid4()),
                        notification_type="APPEAL_DEADLINE",
                        severity="CRITICAL",
                        title=f"Appeal Deadline Missed — Immediate Action Required",
                        message=(
                            f"The {here.appeal_level}-level appeal deadline for "
                            f"${here.amount_disputed:.2f} dispute passed on {here.deadline}. "
                            f"Please contact a Medicare counselor immediately."
                        ),
                        created_at=datetime.utcnow().isoformat()
                    );
                    here ++> notif;

                } elif days_remaining <= DEADLINE_WARNING_DAYS {
                    print(
                        f"[AppealTracker] Deadline in {days_remaining} days for "
                        f"dispute {here.dispute_id} (${here.amount_disputed:.2f})"
                    );
                    severity = "URGENT" if days_remaining <= 7 else "WARNING";
                    notif = Notification(
                        notification_id=str(uuid4()),
                        notification_type="APPEAL_DEADLINE",
                        severity=severity,
                        title=f"Appeal Deadline in {days_remaining} Days",
                        message=(
                            f"Level {here.appeal_level} appeal deadline is {here.deadline} "
                            f"({days_remaining} days). Dispute: {here.description[:100]}. "
                            f"Amount: ${here.amount_disputed:.2f}"
                        ),
                        created_at=datetime.utcnow().isoformat()
                    );
                    here ++> notif;
                }
            } except Exception as e {
                print(f"[AppealTracker] Error parsing deadline for {here.dispute_id}: {e}");
            }
        }

        # Walk into appeal nodes for decision tracking
        visit [-->];
    }

    can check_appeal_decision with Appeal entry {
        # If decision came in and is unfavorable, escalate to next level
        if here.decision == "UNFAVORABLE" and here.appeal_level < 5 {
            # Find parent dispute
            parent_disputes = [d for d in [here<--] if isinstance(d, Dispute)];
            for dispute in parent_disputes {
                if dispute.appeal_level == here.appeal_level {
                    dispute.status = "OPEN";  # Reopen for next level
                    print(
                        f"[AppealTracker] Unfavorable Level {here.appeal_level} — "
                        f"dispute {dispute.dispute_id} eligible for Level {here.appeal_level + 1}"
                    );
                }
            }
        }
    }
}
