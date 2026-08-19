node Reading { has name: str; has amt: int; has taken: bool = False; }

walker Bucket {
    has neg: int = 0;
    has zero: int = 0;
    has pos: int = 0;
    can sort_one with Reading entry {
        if not here.taken {
            here.taken = True;
            if here.amt < 0 { self.neg += 1; }
            elif here.amt == 0 { self.zero += 1; }
            else { self.pos += 1; }
            visit [-->];
        }
    }
}

def sign_bucket_counts(spec: dict) -> dict {
    adj: dict = spec["adj"]; vals: dict = spec["vals"];
    pool: dict = {};
    for (frm, dests) in adj.items() {
        if frm not in pool { pool[frm] = Reading(name=frm, amt=vals[frm]); }
        for d in dests { if d not in pool { pool[d] = Reading(name=d, amt=vals[d]); } }
    }
    for (frm, dests) in adj.items() { for d in dests { pool[frm] ++> pool[d]; } }
    w = pool[spec["start"]] spawn Bucket();
    return {"neg": w.neg, "zero": w.zero, "pos": w.pos};
}

with entry {
    print(sign_bucket_counts({'adj': {'a': ['b', 'c'], 'b': ['d'], 'c': ['d'], 'd': []}, 'vals': {'a': -2, 'b': 0, 'c': 5, 'd': 7}, 'start': 'a'}));
}
