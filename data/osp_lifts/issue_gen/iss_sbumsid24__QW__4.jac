"""Doubly linked list and hash table — sbumsid24/QW#4."""

node ListNode {
    has data: int;
}

edge Next {}

edge Prev {}

node BucketEntry {
    has key: str;
    has val: int;
}

edge Chain {}

node ProbeNode {
    has v: int;
}

edge ProbeEdge {}

obj DoublyLinkedList {
    has head: ListNode | None = None;
    has tail: ListNode | None = None;
    has length: int = 0;
}

obj HashTable {
    has size: int = 50;
    has bucket_heads: list = [];
}

walker IndexWalker {
    has target: int = 0;
    has steps: int = 0;
    has found: ListNode | None = None;
    has claimed: dict[str, bool] = {};

    can step with ListNode entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        if self.steps == self.target {
            self.found = here;
            disengage;
        }
        self.steps += 1;
        for ch in [here ->:Next:->][?:ListNode] {
            visit :0: [ch];
        } else {
            disengage;
        }
    }
}

walker ListCollectWalker {
    has items: list = [];
    has claimed: dict[str, bool] = {};

    can collect with ListNode entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        self.items.append(here.data);
        for ch in [here ->:Next:->][?:ListNode] {
            visit :0: [ch];
        } else {
            disengage;
        }
    }
}

walker BucketFindWalker {
    has key: str = "";
    has hit: bool = False;
    has found_node: BucketEntry | None = None;
    has claimed: dict[str, bool] = {};

    can find with BucketEntry entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        if here.key == self.key {
            self.hit = True;
            self.found_node = here;
            disengage;
        }
        for ch in [here ->:Chain:->][?:BucketEntry] {
            visit :0: [ch];
        } else {
            disengage;
        }
    }
}

walker ProbeWalker {
    has order: list = [];
    has claimed: dict[str, bool] = {};

    can walk with ProbeNode entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        self.order.append(here.v);
        kids: list[ProbeNode] = [here ->:ProbeEdge:->][?:ProbeNode];
        i = 0;
        while i < len(kids) {
            visit :0: [kids[i]];
            i += 1;
        }
    }
}

walker DemoWalker {
    can run with root entry {
        dll = DoublyLinkedList();
        append(dll, 10);
        append(dll, 20);
        prepend(dll, 5);
        insert_at(dll, 2, 15);
        print_list(dll);
        remove_at(dll, 1);
        print_list(dll);
        ht = HashTable();
        set(ht, "alpha", 1);
        set(ht, "beta", 2);
        print(get(ht, "alpha"));
        print(__str__(ht));
    }
}

def DoublyLinkedList() -> DoublyLinkedList {
    return DoublyLinkedList(head=None, tail=None, length=0);
}

def append(dll: DoublyLinkedList, data: int) -> None {
    nd = ListNode(data=data);
    if dll.head is None {
        dll.head = nd;
        dll.tail = nd;
    } else {
        dll.tail +>:Next:+> nd;
        nd +>:Prev:+> dll.tail;
        dll.tail = nd;
    }
    dll.length += 1;
}

def prepend(dll: DoublyLinkedList, data: int) {
    nd = ListNode(data=data);
    if dll.head is None {
        dll.head = nd;
        dll.tail = nd;
    } else {
        nd +>:Next:+> dll.head;
        dll.head +>:Prev:+> nd;
        dll.head = nd;
    }
    dll.length += 1;
}

def traverse_to_index(dll: DoublyLinkedList, index: int) -> ListNode {
    if index < 0 or index >= dll.length {
        raise IndexError("Index out of range");
    }
    w = dll.head spawn IndexWalker(target=index, claimed={});
    if w.found is None {
        raise IndexError("Index out of range");
    }
    return w.found;
}

def insert_at(dll: DoublyLinkedList, index: int, data: int) -> None {
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
    follower_nodes: list[ListNode] = [leader ->:Next:->][?:ListNode];
    follower = follower_nodes[0];
    new_node = ListNode(data=data);
    leader +>:Next:+> new_node;
    new_node +>:Prev:+> leader;
    new_node +>:Next:+> follower;
    follower +>:Prev:+> new_node;
    dll.length += 1;
}

def remove_at(dll: DoublyLinkedList, index: int) -> None {
    if index < 0 or index >= dll.length {
        raise IndexError("Index out of range");
    }
    if index == 0 {
        old_head = dll.head;
        nxt: list[ListNode] = [old_head ->:Next:->][?:ListNode];
        if len(nxt) > 0 {
            dll.head = nxt[0];
            dll.head -:Prev:- old_head;
        } else {
            dll.head = None;
            dll.tail = None;
        }
        dll.length -= 1;
        return;
    }
    if index == dll.length - 1 {
        old_tail = dll.tail;
        prv: list[ListNode] = [old_tail ->:Prev:->][?:ListNode];
        dll.tail = prv[0];
        dll.tail -:Next:- old_tail;
        dll.length -= 1;
        return;
    }
    leader = traverse_to_index(dll, index - 1);
    unwanted_nodes: list[ListNode] = [leader ->:Next:->][?:ListNode];
    unwanted = unwanted_nodes[0];
    after_nodes: list[ListNode] = [unwanted ->:Next:->][?:ListNode];
    leader -:Next:- unwanted;
    unwanted -:Prev:- leader;
    if len(after_nodes) > 0 {
        after = after_nodes[0];
        leader +>:Next:+> after;
        after +>:Prev:+> leader;
    }
    dll.length -= 1;
}

def dll_to_list(dll: DoublyLinkedList) -> list {
    if dll.head is None {
        return [];
    }
    w = dll.head spawn ListCollectWalker(claimed={});
    return w.items;
}

def print_list(dll: DoublyLinkedList) {
    items = dll_to_list(dll);
    i = 0;
    while i < len(items) {
        if i > 0 {
            print(" <-> ");
        }
        print(items[i]);
        i += 1;
    }
}

def HashTable() -> HashTable {
    heads: list = [];
    i = 0;
    while i < 50 {
        heads.append(None);
        i += 1;
    }
    return HashTable(size=50, bucket_heads=heads);
}

def _hash(ht: HashTable, key: str) -> int {
    total = 0;
    i = 0;
    while i < len(key) {
        total += ord(key[i]);
        i += 1;
    }
    return total % ht.size;
}

def _find_in_bucket(head: BucketEntry | None, key: str) -> BucketEntry | None {
    if head is None {
        return None;
    }
    w = head spawn BucketFindWalker(key=key, claimed={});
    if w.hit {
        return w.found_node;
    }
    return None;
}

def set(ht: HashTable, key: str, val: int) -> None {
    idx = _hash(ht, key);
    existing = _find_in_bucket(ht.bucket_heads[idx], key);
    if existing is not None {
        existing.val = val;
        return;
    }
    entry = BucketEntry(key=key, val=val);
    old_head = ht.bucket_heads[idx];
    if old_head is None {
        ht.bucket_heads[idx] = entry;
    } else {
        entry +>:Chain:+> old_head;
        ht.bucket_heads[idx] = entry;
    }
}

def get(ht: HashTable, key: str) -> int | None {
    idx = _hash(ht, key);
    found = _find_in_bucket(ht.bucket_heads[idx], key);
    if found is None {
        return None;
    }
    return found.val;
}

def remove(ht: HashTable, key: str) -> None {
    idx = _hash(ht, key);
    head = ht.bucket_heads[idx];
    if head is None {
        return;
    }
    if head.key == key {
        nxt: list[BucketEntry] = [head ->:Chain:->][?:BucketEntry];
        if len(nxt) > 0 {
            ht.bucket_heads[idx] = nxt[0];
        } else {
            ht.bucket_heads[idx] = None;
        }
        return;
    }
    prev = head;
    cur_nodes: list[BucketEntry] = [head ->:Chain:->][?:BucketEntry];
    cur = cur_nodes[0];
    while cur is not None {
        if cur.key == key {
            nxt2: list[BucketEntry] = [cur ->:Chain:->][?:BucketEntry];
            prev -:Chain:- cur;
            if len(nxt2) > 0 {
                prev +>:Chain:+> nxt2[0];
            }
            return;
        }
        prev = cur;
        more: list[BucketEntry] = [cur ->:Chain:->][?:BucketEntry];
        if len(more) > 0 {
            cur = more[0];
        } else {
            cur = None;
        }
    }
}

def __str__(ht: HashTable) -> str {
    parts: list = [];
    b = 0;
    while b < ht.size {
        chain_parts: list = [];
        head = ht.bucket_heads[b];
        if head is not None {
            cur = head;
            while cur is not None {
                chain_parts.append(cur.key + "=" + str(cur.val));
                nxt3: list[BucketEntry] = [cur ->:Chain:->][?:BucketEntry];
                if len(nxt3) > 0 {
                    cur = nxt3[0];
                } else {
                    cur = None;
                }
            }
        }
        if len(chain_parts) > 0 {
            parts.append(str(b) + ":" + ",".join(chain_parts));
        }
        b += 1;
    }
    return "{" + ";".join(parts) + "}";
}
