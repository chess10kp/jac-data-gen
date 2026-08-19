node Book {}
node Visitor { has name: str, message: str; }

walker LongScan {
    has msgs: list = [], best: str = "";
    can start with Book entry { visit [-->][?:Visitor]; }
    can grab with Visitor entry { self.msgs.append(here.message); }
    can pick with exit {
        self.msgs.sort();
        for m in self.msgs { if len(m) > len(self.best) { self.best = m; } }
    }
}

def longest_message(spec: dict) -> str {
    book = Book();
    for e in spec["entries"] {
        book ++> Visitor(name=str(e["name"]), message=str(e["message"]));
    }
    return (book spawn LongScan()).best;
}

with entry {
    print(longest_message({'entries': [{'name': 'ana', 'message': 'hello there'}, {'name': 'bo', 'message': 'hi'}, {'name': 'cy', 'message': 'great site'}]}));
}
