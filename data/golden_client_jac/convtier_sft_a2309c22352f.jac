node Machine { has name: str; has load: int; }

walker IdleScan {
    has pairs: list = [];
    has pick: str = "";
    can scan with Root entry { visit [-->][?:Machine]; }
    can weigh with Machine entry { self.pairs.append((here.load, here.name)); }
    can choose with exit {
        if self.pairs {
            self.pairs.sort();
            self.pick = self.pairs[0][1];
        }
    }
}

def idle_machine(spec: dict) -> str {
    for old in [root -->] { root del --> old; }
    for m in list(spec["machines"]) {
        root ++> Machine(name=str(m["name"]), load=int(m["load"]));
    }
    return (root spawn IdleScan()).pick;
}

with entry {
    print(idle_machine({'machines': [{'name': 'web1', 'load': 30}, {'name': 'web2', 'load': 10}]}));
}
