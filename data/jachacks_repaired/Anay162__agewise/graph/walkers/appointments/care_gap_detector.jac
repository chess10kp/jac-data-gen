"""CareGapDetector walker — finds gaps in preventive care.

Traverses a Patient's appointment history and creates CareGap nodes
for any required visit type that is overdue based on standard intervals.
"""

import from graph.nodes.patient { Patient }
import from graph.nodes.appointment { Appointment }
import from graph.nodes.care_gap { CareGap }

import from datetime { datetime }
import from uuid { uuid4 }

glob PCP_KEYWORDS: list[str]    = ["primary care", "internal medicine", "family medicine", "general practice", "pcp"];
glob DENTAL_KEYWORDS: list[str] = ["dental", "dentist", "orthodont"];
glob VISION_KEYWORDS: list[str] = ["ophthalm", "optometr", "eye"];

glob RULES: list = [
    ("MISSED_PCP",    PCP_KEYWORDS,    365, 90,  "Primary Care Physician"),
    ("MISSED_DENTAL", DENTAL_KEYWORDS, 365, 90,  "Dentist"),
    ("MISSED_VISION", VISION_KEYWORDS, 730, 180, "Eye Doctor")
];


"""Walks Patient, checks appointment history, creates CareGap nodes."""
walker CareGapDetector {

    has gaps_created: int = 0;

    can start with Patient entry {
        appts: list[Appointment] = [n for n in [here-->] if isinstance(n, Appointment)];
        existing_gap_types: list[str] = [g.gap_type for g in [n for n in [here-->] if isinstance(n, CareGap)] if g.resolved == False];

        for rule in RULES {
            gap_type:  str      = str(rule[0]);
            keywords:  list     = list(rule[1]);
            interval:  int      = int(rule[2]);
            threshold: int      = int(rule[3]);
            specialty: str      = str(rule[4]);

            if gap_type in existing_gap_types {
                continue;
            }

            # Find most-recent completed visit matching this specialty
            last_visit: str = "";
            for appt in appts {
                if appt.status == "COMPLETED" {
                    combined: str = appt.specialty + " " + appt.provider_name + " " + appt.purpose;
                    if any(kw in combined.lower() for kw in keywords) {
                        if last_visit == "" or appt.appointment_date > last_visit {
                            last_visit = appt.appointment_date;
                        }
                    }
                }
            }

            # Compute days_ago
            days_ago: int = 99999;
            if (not (last_visit == "")) {
                try {
                    dt: datetime = datetime.strptime(last_visit, "%Y-%m-%d");
                    now: datetime = datetime.utcnow();
                    delta = now - dt;
                    days_ago = delta.days;
                } except Exception {
                    days_ago = 99999;
                }
            }

            if days_ago > interval {
                overdue: int = days_ago - interval;
                urgency: str = "LOW";
                if overdue > threshold {
                    urgency = "HIGH";
                } elif overdue > 30 {
                    urgency = "MEDIUM";
                }
                if days_ago == 99999 {
                    urgency = "HIGH";
                }

                today_str: str = str(datetime.utcnow())[:10];

                here ++> CareGap(
                    gap_id                    = str(uuid4()),
                    gap_type                  = gap_type,
                    last_visit_date           = last_visit,
                    recommended_interval_days = interval,
                    days_overdue              = (overdue if (not (last_visit == "")) else 0),
                    urgency                   = urgency,
                    specialty_needed          = specialty,
                    detected_date             = today_str,
                    acknowledged              = False,
                    resolved                  = False
                );
                self.gaps_created += 1;
            }
        }

        report {
            "patient":                    here.name,
            "gaps_created":               self.gaps_created,
            "total_appointments_checked": len(appts)
        };
    }
}
