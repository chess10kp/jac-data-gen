"""Fleet fuel economy: Vehicle nodes on root with FillUp nodes attached."""

import sys;

node Vehicle {
    has plate: str;
}

node FillUp {
    has odometer: int;
    has liters: float;
}

def find_vehicle(plate: str) -> Vehicle | None {
    for v in [root -->[?:Vehicle]] {
        if v.plate == plate.upper() {
            return v;
        }
    }
    return None;
}

def fills_of(v: Vehicle) -> list[FillUp] {
    return sorted([f for f in [v -->[?:FillUp]]], key=lambda (f: FillUp) -> int { return f.odometer; });
}

walker AddVehicle {
    has plate: str;

    can add with Root entry {
        v = find_vehicle(self.plate);
        report v if v is not None else here ++> Vehicle(plate=self.plate.upper());
    }
}

walker RecordFill {
    has plate: str;
    has odometer: int;
    has liters: float;

    can record with Root entry {
        v = find_vehicle(self.plate);
        if v is None {
            report {"ok": False, "error": f"unknown vehicle {self.plate.upper()}"};
            return;
        }
        fills = fills_of(v);
        if fills and self.odometer <= fills[-1].odometer {
            report {"ok": False, "error": f"odometer must exceed {fills[-1].odometer}"};
            return;
        }
        v ++> FillUp(odometer=int(self.odometer), liters=float(self.liters));
        report {"ok": True};
    }
}

walker Economy {
    has plate: str;
    has readings: list[tuple[int, float]] = [];

    can start with Root entry {
        v = find_vehicle(self.plate);
        if v is not None {
            visit [v -->[?:FillUp]];
        }
    }

    can collect with FillUp entry {
        self.readings.append((here.odometer, here.liters));
    }

    can finish with exit {
        r = sorted(self.readings);
        if len(r) < 2 {
            report 0.0;
        } else {
            distance = r[-1][0] - r[0][0];
            liters = sum([l for (_, l) in r[1:]]);
            report round(liters / distance * 100, 2);
        }
    }
}

def run_cli(argv: list[str]) -> int {
    cmd = argv[0] if argv else "";
    if cmd == "add" and len(argv) == 2 {
        root spawn AddVehicle(plate=argv[1]);
        print(f"added {argv[1].upper()}");
    } elif cmd == "fill" and len(argv) == 4 {
        r = (root spawn RecordFill(plate=argv[1], odometer=int(argv[2]), liters=float(argv[3]))).reports[0];
        print("ok" if r["ok"] else f"error: {r['error']}");
    } elif cmd == "economy" and len(argv) == 2 {
        e = (root spawn Economy(plate=argv[1])).reports[0];
        print(f"{argv[1].upper()} {e} L/100km");
    } else {
        print("usage: add PLATE | fill PLATE ODO LITERS | economy PLATE");
        return 2;
    }
    return 0;
}

with entry:__main__ {
    sys.`exit(run_cli(sys.argv[1:]));
}
