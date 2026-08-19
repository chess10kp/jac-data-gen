node Person { has name: str; }
node Device {
    has label: str;
    has on: bool;
    can report with PowerProbe entry { if self.on { visitor.found = True; } }
}

walker PowerProbe {
    has found: bool = False;
    can seek with Person entry { visit [-->][?:Device]; }
}

def has_powered_device(spec: dict) -> bool {
    who: str = str(spec["who"]);
    pnodes: dict = {};
    for (nm, devices) in dict(spec["people"]).items() {
        p = Person(name=str(nm));
        pnodes[nm] = p;
        for d in list(devices) { p ++> Device(label=str(d["label"]), on=bool(d["on"])); }
    }
    if who not in pnodes { return False; }
    return (pnodes[who] spawn PowerProbe()).found;
}

with entry {
    print(has_powered_device({'people': {'ana': [{'label': 'lamp', 'on': False}, {'label': 'fan', 'on': True}], 'bo': [{'label': 'tv', 'on': False}]}, 'who': 'ana'}));
}
