node Book {}
node Day { has date: str; }
node Visitor { has name: str; }

walker ReportScan {
    has pairs: list = [], day_count: int = 0, result: str = "";
    can start with Book entry { visit [-->][?:Day]; }
    can size with Day entry {
        self.day_count += 1;
        self.pairs.append((here.date, len([-->][?:Visitor])));
    }
    can render with exit {
        self.pairs.sort();
        total = 0;
        best_d = "none";
        best_n = -1;
        for (dt, n) in self.pairs {
            total += n;
            if n > best_n { best_d = dt; best_n = n; }
        }
        self.result = f"days={self.day_count} visitors={total} busiest={best_d}";
    }
}

def guestbook_report(spec: dict) -> str {
    book = Book();
    for day in spec["days"] {
        d = Day(date=str(day["date"]));
        book ++> d;
        for nm in day["visitors"] { d ++> Visitor(name=str(nm)); }
    }
    return (book spawn ReportScan()).result;
}

with entry {
    print(guestbook_report({'days': [{'date': 'd1', 'visitors': ['ana', 'bo']}, {'date': 'd2', 'visitors': ['cy', 'dee', 'eli']}, {'date': 'd3', 'visitors': ['fay']}]}));
}
