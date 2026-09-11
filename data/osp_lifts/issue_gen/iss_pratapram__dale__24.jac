"""Entity resolution over shared attributes, lifted to OSP.

The bucket map and expanded adjacency become an alternating typed graph:
Record nodes --HasValue--> ValueNode --ValueOf--> Record. Component
labeling becomes one flooding walker per unresolved component sharing a
claim map across spawns (the cycle policy -- jac walkers do not dedupe,
so every record/value key is guarded once). Entity id stays min(record
id) per component, so results are order-independent.
Ref: pratapram/dale#24
"""
node Record {
    has rkey: str;
}
node ValueNode {
    has vkey: str;
}
edge HasValue {}  # record -> shared attribute value
edge ValueOf {}   # value -> member record

obj Resolver {
    has records: dict;
    has values: dict;
    has order: list;
}

walker LabelFlood {
    # Cycle policy: claim-once across BOTH node kinds, shared by all
    # spawns of one component sweep.
    has claimed: dict[str, bool] = {};
    has members: list[str] = [];
    has best_id: int = -1;

    can step_record with Record entry {
        if here.rkey in self.claimed {
            skip;
        }
        self.claimed[here.rkey] = True;
        self.members.append(here.rkey);
        rid = int(here.rkey[2:]);
        if self.best_id < 0 or rid < self.best_id {
            self.best_id = rid;
        }
        visit [->:HasValue:->];
    }

    can step_value with ValueNode entry {
        k = "v:" + here.vkey;
        if k in self.claimed {
            skip;
        }
        self.claimed[k] = True;
        visit [->:ValueOf:->];
    }
}

"""Resolve ``records`` into entities linked through ``link_fields``.

Records sharing a non-blank value in any link field are transitively one
entity; blank or missing values never merge. Returns {record_id: entity_id}
with entity_id = smallest record id in the component.
"""
def resolve_entities(records: list, link_fields: list) -> dict {
    res = Resolver(records={}, values={}, order=[]);
    for rec in records {
        rkey = f"r:{rec['id']}";
        if rkey not in res.records {
            n = Record(rkey=rkey);
            root ++> n;
            res.records[rkey] = n;
            res.order.append(rkey);
        }
    }
    for rec in records {
        rkey = f"r:{rec['id']}";
        for f in link_fields {
            val = rec.get(f);
            # Blank values NEVER merge: absence of an email is not a
            # shared email (the issue's most-likely correctness bug).
            if val is not None and val != "" {
                vkey = f"{f}:{val}";
                if vkey not in res.values {
                    vn = ValueNode(vkey=vkey);
                    root ++> vn;
                    res.values[vkey] = vn;
                }
                res.records[rkey] +>:HasValue:+> res.values[vkey];
                res.values[vkey] +>:ValueOf:+> res.records[rkey];
            }
        }
    }
    labels: dict = {};
    claimed: dict[str, bool] = {};
    for rkey in res.order {
        if rkey in claimed {
            continue;
        }
        start: Record = res.records[rkey];
        w = start spawn LabelFlood(claimed=claimed);
        ent = w.best_id;
        for mk in w.members {
            labels[int(mk[2:])] = ent;
        }
    }
    return labels;
}
