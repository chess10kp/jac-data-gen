node Tag { has text: str; }

walker JoinTags {
    has joined: str = "";
    can read with Tag entry {
        if self.joined == "" { self.joined = here.text; }
        else { self.joined = self.joined + "-" + here.text; }
        visit [-->];
    }
}

def join_chain_labels(spec: dict) -> str {
    labels: list = list(spec["labels"]);
    if not labels { return ""; }
    head = Tag(text=str(labels[0]));
    prev = head;
    for lb in labels[1:] {
        nxt = Tag(text=str(lb));
        prev ++> nxt;
        prev = nxt;
    }
    return (head spawn JoinTags()).joined;
}

with entry {
    print(join_chain_labels({'labels': ['red', 'green', 'blue']}));
}
