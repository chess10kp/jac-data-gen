node Book {}
node Day { has date: str; }
node Visitor { has name: str, day: str; }

walker RepeatScan {
    has pairs: list = [], result: list = [];
    can start with Book entry { visit [-->][?:Day]; }
    can descend with Day entry { visit [-->][?:Visitor]; }
    can collect with Visitor entry { self.pairs.append((here.name, here.day)); }
    can merge with exit {
        by_name: dict = {};
        for (nm, dt) in self.pairs {
            if nm not in by_name { by_name[nm] = []; }
            if dt not in by_name[nm] { by_name[nm].append(dt); }
        }
        for (nm, ds) in by_name.items() {
            if len(ds) > 1 { self.result.append(nm); }
        }
        self.result.sort();
    }
}

def repeat_visitors(spec: dict) -> list {
    book = Book();
    for day in spec["days"] {
        d = Day(date=str(day["date"]));
        book ++> d;
        for nm in day["visitors"] { d ++> Visitor(name=str(nm), day=str(day["date"])); }
    }
    return (book spawn RepeatScan()).result;
}

with entry {
    print(repeat_visitors({'days': [{'date': 'd1', 'visitors': ['ana', 'bo']}, {'date': 'd2', 'visitors': ['bo', 'cy']}, {'date': 'd3', 'visitors': ['ana', 'bo']}]}));
}
