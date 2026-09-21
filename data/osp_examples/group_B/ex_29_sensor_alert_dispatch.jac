"""Industrial sensor patrol.

One monitor ability handles two sensor kinds through a union trigger
(``with TemperatureSensor | SmokeSensor entry``); because both kinds
inherit their reporting interface from the Sensor base, the union-typed
``here`` can be polled without knowing which concrete kind fired.
"""

node Sensor {
    has unit_id: str;

    def is_alert() -> bool {
        return False;
    }

    def reading() -> str {
        return f"{self.unit_id}";
    }
}

node TemperatureSensor(Sensor) {
    has celsius: float = 0.0;

    override def is_alert() -> bool {
        return self.celsius > 75.0;
    }

    override def reading() -> str {
        return f"{self.unit_id}: temperature {self.celsius} C";
    }
}

node SmokeSensor(Sensor) {
    has ppm: float = 0.0;

    override def is_alert() -> bool {
        return self.ppm > 50.0;
    }

    override def reading() -> str {
        return f"{self.unit_id}: smoke {self.ppm} ppm";
    }
}

node Zone {
    has zone_id: str;
}

walker SafetyMonitor {
    has alerts: list[str] = [];

    can start with Root entry {
        visit [-->];
    }

    can patrol with Zone entry {
        print(f"sweeping zone {here.zone_id}");
        visit [-->];
    }

    # Union trigger: this single ability runs for BOTH sensor kinds.
    can inspect with TemperatureSensor | SmokeSensor entry {
        if here.is_alert() {
            self.alerts.append(here.reading());
            print(f"[ALERT] {here.reading()}");
        } else {
            print(f"nominal: {here.reading()}");
        }
    }
}

with entry {
    zone_a = Zone(zone_id="A");
    zone_b = Zone(zone_id="B");
    root ++> zone_a ++> zone_b;

    t1 = TemperatureSensor(unit_id="T-1", celsius=64.0);
    s1 = SmokeSensor(unit_id="S-1", ppm=12.0);
    t2 = TemperatureSensor(unit_id="T-2", celsius=91.5);
    s2 = SmokeSensor(unit_id="S-2", ppm=77.0);
    zone_a ++> t1;
    zone_a ++> s1;
    zone_b ++> t2;
    zone_b ++> s2;

    watch = SafetyMonitor();
    root spawn watch;
    print(f"patrol finished with {len(watch.alerts)} alert(s): {watch.alerts}");
}
