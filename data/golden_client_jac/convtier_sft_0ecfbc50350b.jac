node Board {}
node Metric { has name: str; }
node Reading { has metric: str, value: int; }

walker SpikeScan {
    has names: list = [], readings: list = [], result: dict = {};
    can start with Board entry { visit [-->][?:Metric]; }
    can note with Metric entry {
        self.names.append(here.name);
        visit [-->][?:Reading];
    }
    can collect with Reading entry { self.readings.append((here.metric, here.value)); }
    can compute with exit {
        self.names.sort();
        for nm in self.names {
            vals: list = [];
            for (m, v) in self.readings { if m == nm { vals.append(v); } }
            spikes = 0;
            if vals {
                mean = sum(vals) / len(vals);
                for v in vals { if v > mean { spikes += 1; } }
            }
            self.result[nm] = spikes;
        }
    }
}

def metric_spikes(spec: dict) -> dict {
    board = Board();
    for m in spec["metrics"] {
        met = Metric(name=str(m["name"]));
        board ++> met;
        for v in m["values"] { met ++> Reading(metric=str(m["name"]), value=int(v)); }
    }
    return (board spawn SpikeScan()).result;
}

with entry {
    print(metric_spikes({'metrics': [{'name': 'cpu', 'values': [10, 90, 20]}, {'name': 'mem', 'values': [50, 50]}]}));
}
