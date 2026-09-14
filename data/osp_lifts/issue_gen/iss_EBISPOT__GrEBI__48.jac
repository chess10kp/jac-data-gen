# EBISPOT/GrEBI#48
# Inverse predicates are canonicalized during ingest; sub-properties expand at query time.

node Predicate {
    has pid: str;
}

edge SubProperty {}
edge Inverse {}

node Assertion {
    has source: str;
    has predicate: str;
    has target: str;
}

obj PredicateMetadata {
    has by_id: dict[str, Predicate] = {};
    has descendants: dict[str, list[str]] = {};
    has inverse_of: dict[str, str] = {};
}

walker DescendantWalker {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];

    can step with Predicate entry {
        if here.pid in self.claimed {
            skip;
        }
        self.claimed[here.pid] = True;
        self.found.append(here.pid);
        print(here.pid);
        for child in [here ->:SubProperty:->][?:Predicate] {
            visit :0: [child];
        }
    }
}

def build_metadata(
    predicate_ids: list[str],
    subproperty_pairs: list[list[str]],
    inverse_pairs: list[list[str]]
) -> PredicateMetadata {
    index = PredicateMetadata();
    nodes: list[Predicate] = [];

    for predicate_id in predicate_ids {
        if predicate_id not in index.by_id {
            pred = Predicate(pid=predicate_id);
            index.by_id[predicate_id] = pred;
            nodes.append(pred);
        }
    }

    for pair in subproperty_pairs {
        if len(pair) >= 2 {
            if pair[0] in index.by_id && pair[1] in index.by_id {
                parent: Predicate = index.by_id[pair[0]];
                child: Predicate = index.by_id[pair[1]];
                parent +>:SubProperty:+> child;
            }
        }
    }

    for pair in inverse_pairs {
        if len(pair) >= 2 {
            if pair[0] in index.by_id && pair[1] in index.by_id {
                left: Predicate = index.by_id[pair[0]];
                right: Predicate = index.by_id[pair[1]];
                left +>:Inverse:+> right;
            }
        }
    }

    for pred in nodes {
        w = pred spawn DescendantWalker(claimed={}, found=[]);
        values: list[str] = [];
        for found_id in w.found {
            if found_id != pred.pid {
                values.append(found_id);
            }
        }
        index.descendants[pred.pid] = sorted(values);
    }

    for pred in nodes {
        for other in [pred ->:Inverse:->][?:Predicate] {
            if pred.pid == other.pid {
                index.inverse_of[pred.pid] = pred.pid;
            } else {
                if pred.pid < other.pid {
                    index.inverse_of[pred.pid] = pred.pid;
                    index.inverse_of[other.pid] = pred.pid;
                } else {
                    index.inverse_of[pred.pid] = other.pid;
                    index.inverse_of[other.pid] = other.pid;
                }
            }
        }
    }

    return index;
}

def canonical_predicate(index: PredicateMetadata, predicate_id: str) -> str {
    if predicate_id in index.inverse_of {
        return index.inverse_of[predicate_id];
    }
    return predicate_id;
}

def expand_predicate(index: PredicateMetadata, predicate_id: str) -> list[str] {
    values: list[str] = [predicate_id];
    if predicate_id in index.descendants {
        for child_id in index.descendants[predicate_id] {
            if child_id not in values {
                values.append(child_id);
            }
        }
    }
    return sorted(values);
}

def canonicalize_assertion(
    index: PredicateMetadata,
    assertion: Assertion
) -> Assertion {
    canonical = canonical_predicate(index, assertion.predicate);
    source_id = assertion.source;
    target_id = assertion.target;

    if assertion.predicate in index.inverse_of {
        if assertion.predicate != canonical {
            source_id = assertion.target;
            target_id = assertion.source;
        }
    }

    return Assertion(
        source=source_id,
        predicate=canonical,
        target=target_id
    );
}

def normalize_assertions(
    index: PredicateMetadata,
    assertions: list[Assertion]
) -> list[Assertion] {
    normalized: list[Assertion] = [];
    for assertion in assertions {
        normalized.append(canonicalize_assertion(index, assertion));
    }
    return normalized;
}
