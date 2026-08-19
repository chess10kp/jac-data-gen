node Hub {}
node Day { has date: str, idx: int; }
node Visitor { has name: str; }

walker RetentionScan {
    has first: list = [], later: list = [], result: int = 0;
    can start with Hub entry { visit [-->][?:Day]; }
    can descend with Day entry { visit [-->][?:Visitor]; }
    can bucket with Visitor entry {
        owners = [<--][?:Day];
        if owners[0].idx == 0 {
            if here.name not in self.first { self.first.append(here.name); }
        } else {
            if here.name not in self.later { self.later.append(here.name); }
        }
    }
    can compute with exit {
        if self.first {
            returned = 0;
            for nm in self.first { if nm in self.later { returned += 1; } }
            self.result = round(100 * returned / len(self.first));
        }
    }
}

def retention_percent(spec: dict) -> int {
    days_spec: list = list(spec["days"]);
    if len(days_spec) < 2 { return 0; }
    hub = Hub();
    idx = 0;
    for d in days_spec {
        day = Day(date=str(d["date"]), idx=idx);
        hub ++> day;
        for nm in d["visitors"] { day ++> Visitor(name=str(nm)); }
        idx += 1;
    }
    return (hub spawn RetentionScan()).result;
}

with entry {
    print(retention_percent({'days': [{'date': 'd1', 'visitors': ['ana', 'bo', 'cy']}, {'date': 'd2', 'visitors': ['bo']}, {'date': 'd3', 'visitors': ['cy', 'dee']}]}));
}
