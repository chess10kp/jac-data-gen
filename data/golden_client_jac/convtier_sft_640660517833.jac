node Board {}
node Metric { has name: str, latest: int; }

walker LatestSum {
    has total: int = 0;
    can fan with Board entry { visit [-->][?:Metric]; }
    can add with Metric entry { self.total += here.latest; }
}

def latest_metric_sum(spec: dict) -> int {
    board = Board();
    for m in spec["metrics"] {
        vals: list = list(m["values"]);
        if vals { board ++> Metric(name=str(m["name"]), latest=int(vals[-1])); }
    }
    return (board spawn LatestSum()).total;
}

with entry {
    print(latest_metric_sum({'metrics': [{'name': 'cpu', 'values': [10, 20, 30]}, {'name': 'mem', 'values': [5]}, {'name': 'disk', 'values': []}]}));
}
