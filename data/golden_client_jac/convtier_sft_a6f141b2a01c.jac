node Setting { has key: str; has val: str; }

walker RegistryDump {
    has entries: list = [];
    has text: str = "";
    can read with Root entry {
        for s in [-->][?:Setting] { self.entries.append(s.key + "=" + s.val); }
    }
    can render with exit {
        self.entries.sort();
        self.text = ";".join(self.entries);
    }
}

def settings_registry(spec: dict) -> str {
    for old in [root -->] { root del --> old; }
    for (k, v) in spec["defaults"].items() {
        root ++> Setting(key=str(k), val=str(v));
    }
    for (k, v) in spec["overrides"].items() {
        for s in [root -->][?:Setting] {
            if s.key == str(k) { s.val = str(v); }
        }
    }
    return (root spawn RegistryDump()).text;
}

with entry {
    print(settings_registry({'defaults': {'theme': 'light', 'font': 12}, 'overrides': {'theme': 'dark', 'ghost': 1}}));
}
