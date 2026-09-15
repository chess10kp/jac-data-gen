"""sbumsid24/EW#2 — doubly linked list and chained hash table OSP lift."""

node DllNode {
    has data: int;
    has slot: str;
}

node DllList {
    has length: int = 0;
    has head: DllNode | None = None;
    has tail: DllNode | None = None;
}

edge DllFwd {}
edge DllBack {}

node HtTable {
    has size: int = 50;
    has heads: dict[int, HtEntry | None] = {};
}

node HtEntry {
    has key: str;
    has value: int;
    has eid: str;
}

edge HtChain {}

node ProbeNode {
    has nid: str;
    has val: int;
}

edge ProbeEdge {}

walker DllIndexWalker {
    has target: int;
    has pos: int = 0;
    has result: DllNode | None = None;
    has claimed: dict[str, bool] = {};
    can stride with DllNode entry {
        if here.slot in self.claimed { skip; }
        self.claimed[here.slot] = True;
        print("index " + here.slot + " @" + str(self.pos));
        if self.pos == self.target {
            self.result = here;
            disengage;
        }
        self.pos += 1;
        nxt: list[DllNode] = [];
        for ch in [here ->:DllFwd:->][?:DllNode] {
            nxt.append(ch);
        }
        if nxt {
            visit :0: nxt;
        } else {
            disengage;
        }
    }
}

walker DllPrintWalker {
    has parts: list[str] = [];
    has claimed: dict[str, bool] = {};
    can stride with DllNode entry {
        if here.slot in self.claimed { skip; }
        self.claimed[here.slot] = True;
        print("print " + str(here.data));
        self.parts.append(str(here.data));
        nxt: list[DllNode] = [];
        for ch in [here ->:DllFwd:->][?:DllNode] {
            nxt.append(ch);
        }
        if nxt {
            visit :0: nxt;
        } else {
            disengage;
        }
    }
}

walker HtFindWalker {
    has want: str;
    has found: HtEntry | None = None;
    has claimed: dict[str, bool] = {};
    can scan with HtEntry entry {
        if here.eid in self.claimed { skip; }
        self.claimed[here.eid] = True;
        print("scan " + here.key);
        if here.key == self.want {
            self.found = here;
            disengage;
        }
        nxt: list[HtEntry] = [];
        for ch in [here ->:HtChain:->][?:HtEntry] {
            nxt.append(ch);
        }
        if nxt {
            visit :0: nxt;
        } else {
            disengage;
        }
    }
}

walker ProbeWalker {
    has order: list[str] = [];
    has claimed: dict[str, bool] = {};
    can go with ProbeNode entry {
        if here.nid in self.claimed { skip; }
        self.claimed[here.nid] = True;
        print("probe " + here.nid);
        self.order.append(here.nid);
        kids: list[ProbeNode] = [];
        for ch in [here ->:ProbeEdge:->][?:ProbeNode] {
            kids.append(ch);
        }
        visit :0: kids;
    }
}

def Node(data: int) -> DllNode {
    nd = DllNode(data=data, slot="node_" + str(data));
    root ++> nd;
    return nd;
}

def DoublyLinkedList() -> DllList {
    lst = DllList(length=0, head=None, tail=None);
    root ++> lst;
    return lst;
}

def _connect_dll(a: DllNode, b: DllNode) {
    a +>:DllFwd:+> b;
    b +>:DllBack:+> a;
}

def append(dll: DllList, data: int) {
    nd = DllNode(data=data, slot="d" + str(dll.length) + "a");
    root ++> nd;
    if dll.length == 0 {
        dll.head = nd;
        dll.tail = nd;
    } else {
        tail = dll.tail;
        if tail {
            _connect_dll(tail, nd);
        }
        dll.tail = nd;
    }
    dll.length += 1;
}

def prepend(dll: DllList, data: int) {
    nd = DllNode(data=data, slot="d" + str(dll.length) + "p");
    root ++> nd;
    if dll.length == 0 {
        dll.head = nd;
        dll.tail = nd;
    } else {
        head = dll.head;
        if head {
            _connect_dll(nd, head);
        }
        dll.head = nd;
    }
    dll.length += 1;
}

def traverse_to_index(dll: DllList, index: int) -> DllNode {
    if index < 0 or index >= dll.length {
        raise IndexError("Index out of range");
    }
    head = dll.head;
    if not head {
        raise IndexError("Index out of range");
    }
    w = head spawn DllIndexWalker(target=index, claimed={});
    if w.result {
        return w.result;
    }
    raise IndexError("Index out of range");
}

def insert_at(dll: DllList, index: int, data: int) {
    if index < 0 or index > dll.length {
        raise IndexError("Index out of range");
    }
    if index == 0 {
        prepend(dll, data);
        return;
    }
    if index == dll.length {
        append(dll, data);
        return;
    }
    leader = traverse_to_index(dll, index - 1);
    follower: DllNode | None = None;
    for ch in [leader ->:DllFwd:->][?:DllNode] {
        follower = ch;
    }
    nd = DllNode(data=data, slot="d" + str(dll.length) + "i");
    root ++> nd;
    leader +>:DllFwd:+> nd;
    nd +>:DllBack:+> leader;
    if follower {
        nd +>:DllFwd:+> follower;
        follower +>:DllBack:+> nd;
    }
    dll.length += 1;
}

def remove_at(dll: DllList, index: int) {
    if index < 0 or index >= dll.length {
        raise IndexError("Index out of range");
    }
    victim = traverse_to_index(dll, index);
    prev: DllNode | None = None;
    for ch in [victim ->:DllBack:->][?:DllNode] {
        prev = ch;
    }
    nxt: DllNode | None = None;
    for ch in [victim ->:DllFwd:->][?:DllNode] {
        nxt = ch;
    }
    if not prev {
        dll.head = nxt;
    } else if nxt {
        prev +>:DllFwd:+> nxt;
    }
    if not nxt {
        dll.tail = prev;
    } else if prev {
        nxt +>:DllBack:+> prev;
    }
    dll.length -= 1;
}

def print_list(dll: DllList) {
    head = dll.head;
    if not head {
        print("None");
        print("Length: " + str(dll.length));
        return;
    }
    w = head spawn DllPrintWalker(claimed={});
    line = "";
    i = 0;
    while i < len(w.parts) {
        if i > 0 {
            line = line + " <-> ";
        }
        line = line + w.parts[i];
        i += 1;
    }
    print("None <-> " + line + " <-> None");
    print("Length: " + str(dll.length));
}

def _hash_key(key: str, size: int) -> int {
    total = 0;
    j = 0;
    while j < len(key) {
        total += ord(key[j]);
        j += 1;
    }
    return total % size;
}

def HashTable() -> HtTable {
    tbl = HtTable(size=50, heads={});
    root ++> tbl;
    b = 0;
    while b < tbl.size {
        tbl.heads[b] = None;
        b += 1;
    }
    return tbl;
}

def _chain_tail(head: HtEntry) -> HtEntry {
    cur = head;
    nxt: HtEntry | None = None;
    for ch in [cur ->:HtChain:->][?:HtEntry] {
        nxt = ch;
    }
    while nxt {
        cur = nxt;
        nxt = None;
        for ch in [cur ->:HtChain:->][?:HtEntry] {
            nxt = ch;
        }
    }
    return cur;
}

def ht_put(tbl: HtTable, key: str, value: int) {
    bucket = _hash_key(key, tbl.size);
    head = tbl.heads[bucket];
    if head {
        w = head spawn HtFindWalker(want=key, claimed={});
        if w.found {
            w.found.value = value;
            return;
        }
    }
    ent = HtEntry(key=key, value=value, eid=key + "#" + str(bucket) + "#" + str(value));
    root ++> ent;
    if head {
        tail = _chain_tail(head);
        tail +>:HtChain:+> ent;
    } else {
        tbl.heads[bucket] = ent;
    }
}

def ht_get(tbl: HtTable, key: str) -> int | None {
    bucket = _hash_key(key, tbl.size);
    head = tbl.heads[bucket];
    if not head {
        return None;
    }
    w = head spawn HtFindWalker(want=key, claimed={});
    if w.found {
        return w.found.value;
    }
    return None;
}

def run_probe() -> list[str] {
    a = ProbeNode(nid="a", val=1);
    root ++> a;
    b = ProbeNode(nid="b", val=2);
    root ++> b;
    c = ProbeNode(nid="c", val=3);
    root ++> c;
    a +>:ProbeEdge:+> b;
    b +>:ProbeEdge:+> c;
    c +>:ProbeEdge:+> a;
    w = a spawn ProbeWalker(claimed={});
    return w.order;
}
