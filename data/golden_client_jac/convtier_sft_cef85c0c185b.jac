node Card { has word: str; }

walker LenCount {
    has chars: int = 0;
    can weigh with Card entry { self.chars += len(here.word); visit [-->]; }
}

def link_cards(words: list, at: int) -> Card {
    c = Card(word=str(words[at]));
    if at + 1 < len(words) { c ++> link_cards(words, at + 1); }
    return c;
}

def total_label_length(spec: dict) -> int {
    if not spec["words"] { return 0; }
    head = link_cards(list(spec["words"]), 0);
    counter = head spawn LenCount();
    return counter.chars;
}

with entry {
    print(total_label_length({'words': ['hi', 'there']}));
}
