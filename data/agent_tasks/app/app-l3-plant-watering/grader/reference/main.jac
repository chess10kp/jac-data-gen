"""Houseplant watering tracker: Plant nodes on root, driven by walkers."""

import sys;
import datetime;

node Plant {
    has name: str;
    has every_days: int;
    has last_watered: str;

    def next_due -> datetime.date {
        return datetime.date.fromisoformat(self.last_watered) + datetime.timedelta(days=self.every_days);
    }
}

walker AddPlant {
    has name: str;
    has every_days: int;
    has date: str;

    can add with Root entry {
        existing = [p for p in [here -->[?:Plant]] if p.name == self.name];
        if existing {
            plant = existing[0];
            plant.every_days = self.every_days;
            plant.last_watered = self.date;
            report plant;
        } else {
            report here ++> Plant(name=self.name, every_days=self.every_days, last_watered=self.date);
        }
    }
}

walker WaterPlant {
    has name: str;
    has date: str;
    has found: bool = False;

    can start with Root entry {
        visit [here -->[?:Plant]];
    }

    can water with Plant entry {
        if here.name == self.name {
            here.last_watered = self.date;
            self.found = True;
            report here;
            disengage;
        }
    }
}

walker DuePlants {
    has date: str;
    has due: list[str] = [];

    can start with Root entry {
        visit [here -->[?:Plant]];
    }

    can check with Plant entry {
        if here.next_due() <= datetime.date.fromisoformat(self.date) {
            self.due.append(here.name);
        }
    }

    can finish with exit {
        report sorted(self.due);
    }
}

def run_cli(argv: list[str]) -> int {
    if len(argv) == 4 and argv[0] == "add" {
        root spawn AddPlant(name=argv[1], every_days=int(argv[2]), date=argv[3]);
        print(f"added {argv[1]}");
        return 0;
    }
    if len(argv) == 3 and argv[0] == "water" {
        w = root spawn WaterPlant(name=argv[1], date=argv[2]);
        print(f"watered {argv[1]}" if w.found else "no such plant");
        return 0;
    }
    if len(argv) == 2 and argv[0] == "due" {
        names = (root spawn DuePlants(date=argv[1])).reports[0];
        if names {
            for n in names {
                print(n);
            }
        } else {
            print("nothing due");
        }
        return 0;
    }
    print("usage: add NAME DAYS DATE | water NAME DATE | due DATE");
    return 2;
}

with entry:__main__ {
    sys.`exit(run_cli(sys.argv[1:]));
}
