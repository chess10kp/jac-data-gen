"""BillDueDateTracker walker — tracks upcoming/overdue bills and alerts.

Walks all RecurringBill nodes, computes days until next payment,
flags overdue bills, and creates Notification nodes for the adult child.
"""

import from graph.nodes.financial_account { FinancialAccount }
import from graph.nodes.patient { Patient }
import from graph.nodes.notification { Notification }
import from graph.walkers.bills.recurring_bill_detector { RecurringBill }

import from datetime { datetime, date }
import from uuid { uuid4 }

glob UPCOMING_WARNING_DAYS = 5;

walker BillDueDateTracker {
    has today: any = None;


    can start with Patient entry {
        self.today = date.today();
        visit [-->];
    }

    can check_account with FinancialAccount entry {
        visit [-->];
    }

    can check_bill with RecurringBill entry {
        if here.due_day_of_month == 0 {
            disengage;
        }

        today = self.today;
        due_day = here.due_day_of_month;

        # Compute next due date
        if today.day <= due_day {
            next_due = date(today.year, today.month, due_day);
        } else {
            # Next month
            if today.month == 12 {
                next_due = date(today.year + 1, 1, due_day);
            } else {
                next_due = date(today.year, today.month + 1, due_day);
            }
        }

        days_until = (next_due - today).days;
        here.days_until_due = days_until;

        if days_until < 0 {
            here.status = "overdue";
            notif = Notification(
                notification_id=str(uuid4()),
                notification_type="BILL_OVERDUE",
                severity="URGENT",
                title=f"Bill Overdue: {here.biller_name}",
                message=(
                    f"{here.biller_name} bill of ${here.expected_amount:.2f} "
                    f"was due on the {due_day}th and hasn't been detected as paid."
                ),
                created_at=datetime.utcnow().isoformat()
            );
            here ++> notif;
            print(f"[BillDueDateTracker] OVERDUE: {here.biller_name} ${here.expected_amount:.2f}");

        } elif days_until <= UPCOMING_WARNING_DAYS {
            here.status = "upcoming";
            notif = Notification(
                notification_id=str(uuid4()),
                notification_type="BILL_OVERDUE",
                severity="WARNING",
                title=f"Bill Due Soon: {here.biller_name}",
                message=(
                    f"{here.biller_name} bill of ${here.expected_amount:.2f} "
                    f"is due in {days_until} day(s) (on the {due_day}th)."
                ),
                created_at=datetime.utcnow().isoformat()
            );
            here ++> notif;
        } else {
            here.status = "current";
        }
    }
}
