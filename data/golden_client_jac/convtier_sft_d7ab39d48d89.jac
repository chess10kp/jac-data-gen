node Hub {}
node Day { has date: str; }
node Visitor { has name: str; }

walker Tally {
    has total: int = 0;
    can fan with Hub entry { visit [-->][?:Day]; }
    can count with Day entry { self.total += len([-->][?:Visitor]); }
}

def total_signatures(spec: dict) -> int {
    hub = Hub();
    for day in spec["days"] {
        d = Day(date=str(day["date"]));
        hub ++> d;
        for nm in day["visitors"] { d ++> Visitor(name=str(nm)); }
    }
    return (hub spawn Tally()).total;
}

with entry {
    print(total_signatures({'days': [{'date': 'd1', 'visitors': ['ana', 'bo']}, {'date': 'd2', 'visitors': ['cy']}]}));
}
