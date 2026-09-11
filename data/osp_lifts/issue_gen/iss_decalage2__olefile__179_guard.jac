"""OLE2 bounded sector-chain walk, lifted to OSP.

The FAT/MiniFAT linked list becomes Sector nodes chained by typed
NextSect edges; the pointer-chasing while-loop becomes a walker. The
claim map is the explicit cycle policy -- the crafted-file hang in the
issue was exactly an unguarded revisit, so hitting a claimed sector sets
the cycle flag (disengage is safe here: a chain has a single lineage)
and the facade raises the source's ChainCycleError semantics as a
ValueError with the same message.
Ref: decalage2/olefile#179
"""
node Sector {
    has sid: int;
}
edge NextSect {}

glob ENDOFCHAIN: int = -2;
glob FREESECT: int = -1;

"""Loader handle: sector ids resolve through this lookup map."""
obj Fat {
    has sects: dict[int, Sector];
    has table: dict[int, int];

    def resolve(sid: int) -> Sector | None {
        return self.sects.get(sid);
    }
}

"""Deterministic fresh-graph builder from a {sector: next} table."""
def load_fat(table: dict[int, int]) -> Fat {
    fat = Fat(sects={}, table=dict(table));
    for sid in table.keys() {
        s = Sector(sid=sid);
        root ++> s;
        fat.sects[sid] = s;
    }
    nxt: int;
    for sid in table.keys() {
        nxt = table[sid];
        # ENDOFCHAIN terminates; FREESECT and dangling pointers end the chain.
        if nxt != ENDOFCHAIN and nxt != FREESECT and nxt in fat.sects {
            fat.sects[sid] +>:NextSect:+> fat.sects[nxt];
        }
    }
    return fat;
}

walker ChainWalk {
    has claimed: dict[int, bool] = {};
    has chain: list[int] = [];
    has hit_cycle: bool = False;

    can step with Sector entry {
        # Cycle policy: revisit = malformed cyclic chain.
        if here.sid in self.claimed {
            self.hit_cycle = True;
            skip;
        }
        self.claimed[here.sid] = True;
        self.chain.append(here.sid);
        visit [->:NextSect:->] else { disengage; }  # single-lineage chain
    }
}

"""Sector ids of the chain at ``start``, ENDOFCHAIN excluded; raises on cycles."""
def sect_chain(fat: Fat, start: int) -> list[int] {
    if start == ENDOFCHAIN {
        return [];
    }
    s = fat.resolve(start);
    if s is None {
        return [start];  # dangling start: lone sector, chain ends
    }
    w = s spawn ChainWalk(claimed={});
    if w.hit_cycle {
        raise ValueError("cyclic sector chain");
    }
    return w.chain;
}

"""True when the chain from ``start`` is acyclic."""
def is_well_formed(fat: Fat, start: int) -> bool {
    try {
        sect_chain(fat, start);
    } except ValueError {
        return False;
    }
    return True;
}

"""Number of sectors in the chain; -1 when malformed (cyclic)."""
def chain_length(fat: Fat, start: int) -> int {
    try {
        return len(sect_chain(fat, start));
    } except ValueError {
        return -1;
    }
}


test "linear chain materializes in order" {
    fat = load_fat({0: 3, 3: 7, 7: -2});
    assert sect_chain(fat, 0) == [0, 3, 7];
    assert chain_length(fat, 0) == 3;
    assert is_well_formed(fat, 0);
}

test "self-looping MiniFAT entry raises instead of hanging" {
    bad = load_fat({5: 5});
    raised = False;
    try {
        sect_chain(bad, 5);
    } except ValueError {
        raised = True;
    }
    assert raised;
    assert chain_length(bad, 5) == -1;
    assert not is_well_formed(bad, 5);
}

test "two-sector loop detected" {
    loop = load_fat({8: 9, 9: 8});
    assert not is_well_formed(loop, 8);
}

test "free tail tolerated and dangling start isolated" {
    tail = load_fat({2: -1});
    assert sect_chain(tail, 2) == [2];
    fat = load_fat({0: 3, 3: 7, 7: -2});
    assert sect_chain(fat, 42) == [42];
}
