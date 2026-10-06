import from graph.nodes.patient { Patient }
import from graph.nodes.appointment { Appointment }
import from graph.nodes.notification { Notification }

import from datetime { datetime }
import from uuid { uuid4 }


"""Generates reminder notifications for upcoming appointments."""
walker AppointmentReminder {

    has reminders_sent: int = 0,
        lookahead_days: int = 14;

    can start with Patient entry {
        today_str: str = str(datetime.utcnow())[:10];
        appointments = [n for n in [here-->] if isinstance(n, Appointment) and n.status == "SCHEDULED"];

        for appt in appointments {
            if not appt.appointment_date {
                continue;
            }

            appt_date_str: str = str(appt.appointment_date);
            if appt_date_str < today_str {
                continue;
            }

            # Compute days_until by parsing dates
            now_dt: datetime = datetime.utcnow();
            appt_dt: datetime = datetime.strptime(appt_date_str, "%Y-%m-%d");
            delta = appt_dt - now_dt;
            days_until = delta.days;

            if days_until > self.lookahead_days {
                continue;
            }

            if days_until <= 3 and not appt.reminder_sent {
                if days_until <= 1 {
                    severity = "HIGH";
                    title = f"Appointment TOMORROW: {appt.provider_name}";
                } elif days_until == 0 {
                    severity = "CRITICAL";
                    title = f"Appointment TODAY: {appt.provider_name}";
                } else {
                    severity = "MEDIUM";
                    title = f"Upcoming Appointment in {days_until} days: {appt.provider_name}";
                }

                time_str = f" at {appt.appointment_time}" if appt.appointment_time else "";
                location_str = f" — {appt.facility_name}" if appt.facility_name else "";
                message = (
                    f"{appt.purpose or appt.specialty or 'Appointment'} with {appt.provider_name}"
                    f" on {appt.appointment_date}{time_str}{location_str}."
                );
                if appt.notes {
                    message += f" Notes: {appt.notes}";
                }

                notif = Notification(
                    notification_id=str(uuid4()),
                    notification_type="APPOINTMENT_REMINDER",
                    severity=severity,
                    title=title,
                    message=message,
                    metadata=str(appt.appointment_id),
                    created_at=str(datetime.utcnow()),
                    delivered_at="",
                    read_at=""
                );
                here ++> notif;
                appt.reminder_sent = True;
                self.reminders_sent += 1;
                print(f"[AppointmentReminder] Reminder created: {appt.provider_name} in {days_until} day(s)");
            }
        }

        report {"patient": here.name, "reminders_sent": self.reminders_sent};
    }
}
