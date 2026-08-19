node Page { has word: str; has taken: bool = False; }

walker InitialScan {
    has letters: list = [];
    has counts: list = [];
    can skim with Page entry {
        if here.taken { return; }
        here.taken = True;
        letter: str = here.word[0];
        if letter in self.letters {
            idx: int = self.letters.index(letter);
            self.counts[idx] += 1;
        } else {
            self.letters.append(letter);
            self.counts.append(1);
        }
        visit [-->];
    }
}

def label_initial_histogram(spec: dict) -> list {
    book: dict = {};
    for (nid, wd) in spec["labels"].items() { book[nid] = Page(word=str(wd)); }
    for a_id in spec["adj"] {
        for b_id in spec["adj"][a_id] { book[a_id] ++> book[b_id]; }
    }
    origin: str = str(spec["start"]);
    scanner = book[origin] spawn InitialScan();
    pairs: list = [];
    for (lt, ct) in zip(scanner.letters, scanner.counts) { pairs.append([lt, ct]); }
    pairs.sort();
    return pairs;
}

with entry {
    print(label_initial_histogram({'adj': {'n1': ['n2', 'n3'], 'n2': [], 'n3': ['n4'], 'n4': []}, 'labels': {'n1': 'apple', 'n2': 'ant', 'n3': 'berry', 'n4': 'avocado'}, 'start': 'n1'}));
}
