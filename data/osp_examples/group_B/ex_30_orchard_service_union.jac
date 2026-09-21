"""Orchard irrigation maintenance.

Pumps and sprinklers share the Device base, so one crew ability with a
union trigger can reset either kind's service counter and read their
common fields without duplicating code.
"""

node Grove {
    has grove_name: str;
}

node Device {
    has device_id: str;
    has hours_since_service: int = 0;
}

node Pump(Device) {
    has flow_lpm: float = 0.0;
}

node Sprinkler(Device) {
    has radius_m: float = 0.0;
}

walker MaintenanceCrew {
    has serviced: int = 0;

    can start with Root entry {
        visit [-->];
    }

    can tour with Grove entry {
        print(f"entering {here.grove_name}");
        visit [-->];
    }

    # One ability covers both device kinds via the union trigger.
    can service with Pump | Sprinkler entry {
        print(f"serviced {type(here).__name__} {here.device_id} "
              f"(was idle {here.hours_since_service}h)");
        here.hours_since_service = 0;
        self.serviced += 1;
    }
}

with entry {
    north = Grove(grove_name="North Grove");
    south = Grove(grove_name="South Grove");
    root ++> north ++> south;

    p1 = Pump(device_id="P-1", flow_lpm=220.0, hours_since_service=38);
    sp1 = Sprinkler(device_id="SP-1", radius_m=6.5, hours_since_service=12);
    p2 = Pump(device_id="P-2", flow_lpm=180.0, hours_since_service=55);
    sp2 = Sprinkler(device_id="SP-2", radius_m=4.0, hours_since_service=7);
    north ++> p1;
    north ++> sp1;
    south ++> p2;
    south ++> sp2;

    crew = MaintenanceCrew();
    root spawn crew;
    print(f"crew serviced {crew.serviced} devices today");
}
