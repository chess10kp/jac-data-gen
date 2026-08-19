node Dash {}
node Panel { has name: str; }
node Gauge { has name: str, value: int, threshold: int; }

walker AlertScan {
    has result: list = [];
    can start with Dash entry { visit [-->][?:Panel]; }
    can descend with Panel entry { visit [-->][?:Gauge]; }
    can check with Gauge entry {
        if here.value > here.threshold {
            owners = [<--][?:Panel];
            self.result.append(owners[0].name + "/" + here.name);
        }
    }
    can finish with exit { self.result.sort(); }
}

def alert_paths(spec: dict) -> list {
    dash = Dash();
    for p in spec["panels"] {
        panel = Panel(name=str(p["name"]));
        dash ++> panel;
        for m in p["metrics"] {
            panel ++> Gauge(name=str(m["name"]), value=int(m["value"]), threshold=int(m["threshold"]));
        }
    }
    return (dash spawn AlertScan()).result;
}

with entry {
    print(alert_paths({'panels': [{'name': 'sys', 'metrics': [{'name': 'cpu', 'value': 91, 'threshold': 80}, {'name': 'mem', 'value': 40, 'threshold': 50}]}, {'name': 'net', 'metrics': [{'name': 'lag', 'value': 120, 'threshold': 100}]}]}));
}
