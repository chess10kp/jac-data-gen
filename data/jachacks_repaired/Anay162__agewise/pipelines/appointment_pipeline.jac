"""AppointmentPipeline — full appointment flow: sync → detect care gaps → remind → reschedule."""

import from graph.nodes.patient { Patient }
import from graph.walkers.appointments.appointment_sync { AppointmentSync }
import from graph.walkers.appointments.care_gap_detector { CareGapDetector }
import from graph.walkers.appointments.appointment_reminder { AppointmentReminder }
import from graph.walkers.appointments.appointment_reschedule { AppointmentReschedule }

walker AppointmentPipeline {
    can run with Patient entry {
        here spawn AppointmentSync();
        here spawn CareGapDetector();
        here spawn AppointmentReminder(lookahead_days=3);
        here spawn AppointmentReschedule();
        report {"pipeline": "appointment", "status": "complete"};
    }
}
