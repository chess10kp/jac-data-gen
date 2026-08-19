node SecureRoom {
    has clearance_required: int;

    # Generic entry - triggers for ANY walker (no type filter)
    can on_enter with entry {
        print("Someone entered");
    }

    # Walker exiting
    can on_exit with Inspector exit {
        print("Inspector leaving");
    }
}

walker Inspector {
    has clearance: int;

    can start with Root entry {
        visit [-->];
    }

    # Access control lives in the WALKER: disengage is walker-only
    can check_clearance with SecureRoom entry {
        if self.clearance < here.clearance_required {
            print("Access denied");
            disengage;
        }
    }
}
