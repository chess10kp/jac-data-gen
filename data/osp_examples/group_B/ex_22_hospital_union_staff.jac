"""Hospital ward doors.

One ward ability serves two kinds of clinical staff at once using a
union trigger (``with Nurse | Doctor entry``); a plain visitor matches
neither type, so the ward stays silent for them.
"""

node Ward {
    has ward_name: str;

    # Union trigger: fires for a Nurse OR a Doctor, not for others.
    can staff_enter with Nurse | Doctor entry {
        print(f"{visitor.badge} badged into the {self.ward_name} ward");
        visitor.shift_visits += 1;
    }
}

walker Nurse {
    has badge: str;
    has shift_visits: int = 0;

    can start with Root entry {
        visit [-->];
    }

    can make_rounds with Ward entry {
        visit [-->];
    }
}

walker Doctor {
    has badge: str;
    has shift_visits: int = 0;

    can start with Root entry {
        visit [-->];
    }

    can make_rounds with Ward entry {
        visit [-->];
    }
}

# A plain family visitor matches neither type: no ward ability fires
# for them, so their pass through the wards is completely silent.
walker FamilyVisitor {
    can start with Root entry {
        visit [-->];
    }

    can wander with Ward entry {
        visit [-->];
    }
}

with entry {
    icu = Ward(ward_name="ICU");
    general = Ward(ward_name="General");
    root ++> icu ++> general;

    nurse = Nurse(badge="N-101");
    root spawn nurse;
    doctor = Doctor(badge="D-55");
    root spawn doctor;
    guest = FamilyVisitor();
    root spawn guest;

    print(f"nurse visited {nurse.shift_visits} wards, "
          f"doctor visited {doctor.shift_visits}; the family visitor "
          f"triggered no ward response at all");
}
