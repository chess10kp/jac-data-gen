"""Restaurant kitchen health inspection.

One inspector walker binds TWO abilities to the same trigger type
(``with KitchenStation entry``); both run in declaration order on every
station visit. The temperature check uses ``skip`` to leave just its
own ability early while the sibling logging ability still runs.
"""

node KitchenStation {
    has station: str;
    has temp_c: float;
}

walker HealthInspector {
    has violations: int = 0;
    has stops: int = 0;

    can start with Root entry {
        visit [-->];
    }

    # First ability bound to KitchenStation entry.
    can check_temp with KitchenStation entry {
        if here.temp_c <= 40.0 {
            print(f"[temp] {here.station} ok ({here.temp_c} C)");
            skip;  # leave this ability only
        }
        self.violations += 1;
        print(f"[temp] {here.station} TOO WARM ({here.temp_c} C) -- violation");
    }

    # Second ability bound to the SAME trigger: still runs after skip.
    can log_stop with KitchenStation entry {
        self.stops += 1;
        print(f"[log] stop #{self.stops} recorded at {here.station}");
        visit [-->];
    }
}

with entry {
    grill = KitchenStation(station="grill", temp_c=38.0);
    fryer = KitchenStation(station="fryer", temp_c=47.5);
    coldprep = KitchenStation(station="cold prep", temp_c=35.0);
    root ++> grill ++> fryer ++> coldprep;

    inspector = HealthInspector();
    root spawn inspector;
    print(f"inspection done: {inspector.stops} stations visited, "
          f"{inspector.violations} violation(s)");
}
