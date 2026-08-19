node Feed {}
node Event { has hour: int; }

walker PeakScan {
    has tally: dict = {}, result: str = "none";
    can start with Feed entry { visit [-->][?:Event]; }
    can count with Event entry {
        self.tally[here.hour] = self.tally.get(here.hour, 0) + 1;
    }
    can pick with exit {
        if self.tally {
            best_h = -1;
            best_n = -1;
            for h in sorted(self.tally) {
                if self.tally[h] > best_n { best_h = h; best_n = self.tally[h]; }
            }
            self.result = str(best_h) + ":" + str(best_n);
        }
    }
}

def peak_hour(spec: dict) -> str {
    feed = Feed();
    for e in spec["events"] { feed ++> Event(hour=int(e["hour"])); }
    return (feed spawn PeakScan()).result;
}

with entry {
    print(peak_hour({'events': [{'hour': 9}, {'hour': 14}, {'hour': 9}, {'hour': 17}, {'hour': 14}, {'hour': 9}]}));
}
