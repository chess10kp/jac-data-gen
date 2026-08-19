node Hub {}
node Day { has date: str; }
node Visitor { has name: str; }

walker ReturnScan {
    has seen: list = [], result: str = "";
    can start with Hub entry { visit [-->][?:Day]; }
    can check with Day entry {
        names: list = [];
        for v in [-->][?:Visitor] { names.append(v.name); }
        hit = False;
        for nm in names { if nm in self.seen { hit = True; } }
        if hit {
            self.result = here.date;
            disengage;
        }
        for nm in names { if nm not in self.seen { self.seen.append(nm); } }
        visit [-->][?:Day];
    }
}

def first_return_day(spec: dict) -> str {
    hub = Hub();
    days: list = [];
    for d in spec["days"] {
        day = Day(date=str(d["date"]));
        for nm in d["visitors"] { day ++> Visitor(name=str(nm)); }
        days.append(day);
    }
    if days {
        hub ++> days[0];
        for i in range(1, len(days)) { days[i-1] ++> days[i]; }
    }
    return (hub spawn ReturnScan()).result;
}

with entry {
    print(first_return_day({'days': [{'date': 'd1', 'visitors': ['ana', 'bo']}, {'date': 'd2', 'visitors': ['cy']}, {'date': 'd3', 'visitors': ['bo']}]}));
}
