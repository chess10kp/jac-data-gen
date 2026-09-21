"""Toll plaza fare collection.

One Vehicle-entry ability with typed context blocks gives each vehicle
subtype its own handling; revenue accumulates across the sweep and is
printed from the spawn result.
"""

node Vehicle {
    has plate: str;

    def describe() -> str {
        return f"vehicle {self.plate}";
    }

    def toll() -> float {
        return 0.0;
    }

    def helmet_note() -> str {
        return "";
    }
}

node Car(Vehicle) {
    has occupants: int = 1;

    override def describe() -> str {
        return f"car {self.plate} ({self.occupants} occupants)";
    }

    override def toll() -> float {
        return 2.5;
    }
}

node Truck(Vehicle) {
    has tonnage: float;

    override def describe() -> str {
        return f"truck {self.plate} ({self.tonnage} t)";
    }

    override def toll() -> float {
        return 2.5 + self.tonnage * 0.5;
    }
}

node Motorcycle(Vehicle) {
    has has_helmet: bool = True;

    override def describe() -> str {
        tag = "helmet on" if self.has_helmet else "NO helmet";
        return f"motorcycle {self.plate} ({tag})";
    }

    override def toll() -> float {
        return 1.0;
    }

    override def helmet_note() -> str {
        return "" if self.has_helmet else " -- helmet check FAILED";
    }
}

node TollBooth {
    has gate: str;

    can open_gate with TollCollector entry {
        print(f"-- gate {self.gate} opening --");
    }
}

walker TollCollector {
    has revenue: float = 0.0;

    can start with Root entry {
        visit [-->];
    }

    can pass_booth with TollBooth entry {
        visit [-->];
    }

    # Dispatch on the concrete subtype at each vehicle; each kind gets
    # its own handling, not just its own print line.
    can collect with Vehicle entry {
        fare = 0.0;

        ->Car{
            fare = here.toll();  # flat rate, nothing else to consider
            print(f"{here.describe()} pays ${fare:.2f} (flat car rate)");
        }
        ->Truck{
            base = 2.5;
            fare = here.toll();
            tonnage_charge = fare - base;
            print(
                f"{here.describe()} pays ${fare:.2f} "
                f"(${base:.2f} base + ${tonnage_charge:.2f} tonnage)"
            );
        }
        ->Motorcycle{
            fare = here.toll();
            print(f"{here.describe()} pays ${fare:.2f}{here.helmet_note()}");
        }

        self.revenue += fare;
    }
}

with entry {
    booth = TollBooth(gate="G-4");
    c1 = Car(plate="ABC-123", occupants=2);
    t1 = Truck(plate="TRK-9", tonnage=12.0);
    m1 = Motorcycle(plate="MOTO-1", has_helmet=False);
    root ++> booth;
    booth ++> c1;
    booth ++> t1;
    booth ++> m1;

    result = root spawn TollCollector();
    print(f"Gate G-4 collected ${result.revenue:.2f}");
}
