node Hub {}
node Day { has date: str; }
node Visitor { has name: str; }

walker StreakScan {
    has min_count: int;
    has cur: int = 0, best: int = 0;
    can start with Hub entry { visit [-->][?:Day]; }
    can step with Day entry {
        if len([-->][?:Visitor]) >= self.min_count {
            self.cur += 1;
            if self.cur > self.best { self.best = self.cur; }
        } else { self.cur = 0; }
        visit [-->][?:Day];
    }
}

def visitor_streak(spec: dict) -> int {
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
    return (hub spawn StreakScan(min_count=int(spec["min_count"]))).best;
}

with entry {
    print(visitor_streak({'days': [{'date': 'd1', 'visitors': ['a', 'b']}, {'date': 'd2', 'visitors': ['c', 'd', 'e']}, {'date': 'd3', 'visitors': []}, {'date': 'd4', 'visitors': ['f', 'g']}], 'min_count': 2}));
}
