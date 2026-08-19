node Store {}
node Doc { has name: str; has text: str; }

walker CapScan {
    has cap: int;
    has truncated: int = 0, total: int = 0;
    can start with Store entry { visit [-->]; }
    can measure with Doc entry {
        t = here.text;
        if len(t) > self.cap {
            t = t[:self.cap];
            self.truncated += 1;
        }
        self.total += len(t);
    }
}

def capped_docs(spec: dict) -> list {
    store = Store();
    for d in spec["docs"] { store ++> Doc(name=str(d["name"]), text=str(d["text"])); }
    w = store spawn CapScan(cap=int(spec["cap"]));
    return [w.truncated, w.total];
}

with entry {
    print(capped_docs({'docs': [{'name': 'a', 'text': 'hello world'}, {'name': 'b', 'text': 'hi'}], 'cap': 5}));
}
