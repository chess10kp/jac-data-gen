node Book {}
node Day { has date: str; }
node Visitor { has name: str; }

walker ActiveScan {
    has min_count: int;
    has dates: list = [];
    can start with Book entry { visit [-->][?:Day]; }
    can check with Day entry {
        if len([-->][?:Visitor]) >= self.min_count { self.dates.append(here.date); }
    }
    can finish with exit { self.dates.sort(); }
}

def active_days(spec: dict) -> list {
    book = Book();
    for day in spec["days"] {
        d = Day(date=str(day["date"]));
        book ++> d;
        for nm in day["visitors"] { d ++> Visitor(name=str(nm)); }
    }
    return (book spawn ActiveScan(min_count=int(spec["min_count"]))).dates;
}

with entry {
    print(active_days({'days': [{'date': 'd2', 'visitors': ['a', 'b']}, {'date': 'd1', 'visitors': ['c', 'd', 'e']}, {'date': 'd3', 'visitors': ['f']}], 'min_count': 2}));
}
