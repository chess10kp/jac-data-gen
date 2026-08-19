node Hub {}
node Day { has date: str; }
node Visitor { has name: str; }

walker DeltaScan {
    has counts: list = [], deltas: list = [];
    can start with Hub entry { visit [-->][?:Day]; }
    can tally with Day entry {
        self.counts.append(len([-->][?:Visitor]));
        visit [-->][?:Day];
    }
    can diff with exit {
        for i in range(1, len(self.counts)) {
            self.deltas.append(self.counts[i] - self.counts[i-1]);
        }
    }
}

def daily_deltas(spec: dict) -> list {
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
    return (hub spawn DeltaScan()).deltas;
}

with entry {
    print(daily_deltas({'days': [{'date': 'd1', 'visitors': ['a']}, {'date': 'd2', 'visitors': ['b', 'c', 'd']}, {'date': 'd3', 'visitors': ['e', 'f']}]}));
}
