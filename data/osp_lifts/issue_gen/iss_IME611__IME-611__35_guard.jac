# iss_IME611__IME-611__35.jac
"""Corpus map and learning sequence for IME611/IME-611#35."""

node Source {
    has sid: str;
    has title: str;
}

node Concept {
    has cid: str;
    has label: str;
}

node Unit {
    has uid: str;
    has text: str;
    has kind: str;
}

edge Supports {}
edge Depends {}
edge Extracts {}

walker ConceptWalk {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];

    can step with Concept entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        self.found.append(here.cid);
        print(here.label);
        for kid in [here ->:Depends:->][?:Concept] {
            visit :0: [kid];
        }
    }
}

def classify_topic(topic: str, known: list[str]) -> str {
    if topic == "" {
        return "NEW";
    }
    for label in known {
        if topic == label {
            return "EXISTS";
        }
    }
    for label in known {
        if topic in label or label in topic {
            return "EXTENDS";
        }
    }
    return "NEW";
}

def deduplicate(labels: list[str]) -> list[str] {
    unique: list[str] = [];
    for label in labels {
        if label in unique {
            continue;
        }
        unique.append(label);
    }
    return sorted(unique);
}

def review_verdict(topic: str, known: list[str], confidence: int) -> str {
    if confidence < 50 {
        return "UNCERTAIN";
    }
    return classify_topic(topic, known);
}

def map_concepts(source_id: str, title: str, labels: list[str],
    relations: list[list[str]], start_id: str) -> list[str] {
    src = Source(sid=source_id, title=title);
    by_id: dict[str, Concept] = {};
    for label in labels {
        concept = Concept(cid=label, label=label);
        src +>:Supports:+> concept;
        by_id[label] = concept;
    }
    for relation in relations {
        if len(relation) >= 2 {
            if relation[0] in by_id and relation[1] in by_id {
                by_id[relation[0]] +>:Depends:+> by_id[relation[1]];
            }
        }
    }
    if start_id not in by_id {
        return [];
    }
    w = by_id[start_id] spawn ConceptWalk(claimed={});
    return sorted(w.found);
}

def learning_sequence(labels: list[str], relations: list[list[str]],
    start_id: str) -> list[str] {
    src = Source(sid="sequence", title="dependency sequence");
    by_id: dict[str, Concept] = {};
    for label in labels {
        concept = Concept(cid=label, label=label);
        src +>:Supports:+> concept;
        by_id[label] = concept;
    }
    for relation in relations {
        if len(relation) >= 2 {
            if relation[0] in by_id and relation[1] in by_id {
                by_id[relation[0]] +>:Depends:+> by_id[relation[1]];
            }
        }
    }
    if start_id not in by_id {
        return [];
    }
    w = by_id[start_id] spawn ConceptWalk(claimed={});
    return w.found;
}

test "classification and canonical duplicates" {
    assert (classify_topic("map", ["map", "sequence"]) == "EXISTS");
    assert (classify_topic("knowledge map", ["map"]) == "EXTENDS");
    assert (classify_topic("ingestion", ["map"]) == "NEW");
    assert (deduplicate(["map", "sequence", "map", "map"]) == ["map", "sequence"]);
}

test "review confidence and edge cases" {
    assert (review_verdict("map", ["map"], 20) == "UNCERTAIN");
    assert (review_verdict("map", ["map"], 90) == "EXISTS");
    assert (review_verdict("", [], 100) == "NEW");
    assert (deduplicate([]) == []);
}

test "diamond traversal claims shared concept once" {
    labels: list[str] = ["root", "left", "right", "shared"];
    relations: list[list[str]] = [
        ["root", "left"],
        ["root", "right"],
        ["left", "shared"],
        ["right", "shared"]
    ];
    found = map_concepts("seed", "seed corpus", labels, relations, "root");
    sequence = learning_sequence(labels, relations, "root");
    assert (found == ["left", "right", "root", "shared"]);
    assert (sorted(sequence) == ["left", "right", "root", "shared"]);
}

test "unknown identifiers are tolerated" {
    labels: list[str] = ["a", "b"];
    relations: list[list[str]] = [["a", "missing"], ["missing", "b"], ["a", "b"]];
    assert (map_concepts("s", "source", labels, relations, "missing") == []);
    assert (learning_sequence(labels, relations, "missing") == []);
    assert (map_concepts("s", "source", labels, relations, "a") == ["a", "b"]);
}
