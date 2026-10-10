# Hidden tests: modelled on cachetools' CacheTestMixin / LRU / LFU / FIFO / TTL test cases.
import collections;
import from basecache { Cache }
import from policies { FIFOCache, LRUCache, LFUCache }
import from ttl { TTLCache }
import from cachekeys { hashkey, typedkey, methodkey }

def raises(f: Callable[[], any], exc: type) -> bool {
    try {
        f();
    } except exc {
        return True;
    }
    return False;
}

def keyset(c: Cache) -> set[any] {
    return set(iter(c));
}

"""Manual clock for TTL tests."""
obj Timer {
    has now: float = 0.0;

    def __call__ -> float {
        return self.now;
    }

    def tick(dt: float = 1.0) -> None {
        self.now += dt;
    }
}

"""LRU cache that computes missing values (exercises __missing__)."""
obj SquareLRU(LRUCache) {
    def __missing__(key: any) -> any {
        self[key] = key * key;
        return key * key;
    }
}

test "base cache defaults and mapping protocol" {
    c = LRUCache(maxsize=2);
    assert c.maxsize == 2 and c.currsize == 0 and len(c) == 0;
    c[1] = 1;
    c[2] = 2;
    assert len(c) == 2 and c.currsize == 2 and 1 in c and c[1] == 1 and c[2] == 2;
    assert c.get(3) is None and c.get(3, "x") == "x" and c.get(1) == 1;
    assert c.setdefault(1, 9) == 1;
    assert c.pop(2) == 2 and len(c) == 1 and 2 not in c;
    assert c.pop(2, "gone") == "gone";
    assert raises(lambda -> any { return c.pop(2); }, KeyError);
    assert raises(lambda -> any { return c[42]; }, KeyError);
    del c[1];
    assert len(c) == 0 and c.currsize == 0;
    assert raises(lambda -> any { return c.popitem(); }, KeyError);
    c.update({5: 5, 6: 6});
    assert sorted(list(c.keys())) == [5, 6];
    c.clear();
    assert len(c) == 0 and c.currsize == 0;
    assert raises(lambda -> any { return LRUCache(maxsize=-1); }, ValueError);
}

test "instances do not share state" {
    a = FIFOCache(maxsize=3);
    b = FIFOCache(maxsize=3);
    a["x"] = 1;
    assert len(b) == 0 and "x" not in b;
}

test "getsizeof and value too large" {
    c = LRUCache(maxsize=3, getsizeof=lambda (x: int) -> int { return x; });
    c[1] = 1;
    c[2] = 2;
    assert c.currsize == 3 and len(c) == 2;
    c[3] = 3;
    assert len(c) == 1 and c.currsize == 3 and 3 in c;
    assert raises(lambda -> any { c[4] = 4; return None; }, ValueError);
    assert 3 in c and 4 not in c;
    c[1] = 1;
    assert keyset(c) == {1} and c.currsize == 1;
    c[1] = 2;
    assert c.currsize == 2 and c[1] == 2;
    assert raises(lambda -> any { c[5] = -1; return None; }, ValueError);
}

test "lru eviction" {
    c = LRUCache(maxsize=2);
    c[1] = 1;
    c[2] = 2;
    c[3] = 3;
    assert len(c) == 2 and 1 not in c and c[2] == 2 and c[3] == 3;
    c[2];
    c[4] = 4;
    assert keyset(c) == {2, 4};
    c[5] = 5;
    assert keyset(c) == {4, 5};
    c[4] = 44;
    c[6] = 6;
    assert keyset(c) == {4, 6} and c[4] == 44;
    assert c.popitem() == (6, 6);
}

test "lru missing computes and stores" {
    c = SquareLRU(maxsize=2);
    assert c[3] == 9 and 3 in c;
    assert c.get(5) is None;
    assert c.pop(4, None) is None;
    assert c[4] == 16;
    assert keyset(c) == {3, 4};
}

test "fifo eviction ignores reads" {
    c = FIFOCache(maxsize=2);
    c[1] = 1;
    c[2] = 2;
    c[1];
    c[3] = 3;
    assert keyset(c) == {2, 3};
    c[2] = 22;
    c[4] = 4;
    assert keyset(c) == {2, 4};
    assert c.popitem() == (2, 22);
    assert keyset(c) == {4};
}

test "lfu eviction" {
    c = LFUCache(maxsize=2);
    c[1] = 1;
    c[1];
    c[2] = 2;
    c[3] = 3;
    assert keyset(c) == {1, 3};
    c[3];
    c[3];
    c[4] = 4;
    assert keyset(c) == {3, 4};
    c[4];
    c[4];
    c[4];
    c[5] = 5;
    assert keyset(c) == {4, 5};
    assert c.popitem()[0] == 5;
}

test "ttl expiry" {
    t = Timer();
    c = TTLCache(maxsize=2, ttl=2.0, timer=t);
    assert c.ttl == 2.0;
    c[1] = 1;
    assert 1 in c and c[1] == 1 and len(c) == 1;
    t.tick();
    c[2] = 2;
    assert keyset(c) == {1, 2} and c.currsize == 2;
    t.tick();
    assert 1 not in c and raises(lambda -> any { return c[1]; }, KeyError);
    assert keyset(c) == {2} and len(c) == 1 and c.currsize == 1;
    c[3] = 3;
    assert keyset(c) == {2, 3};
    t.tick();
    assert keyset(c) == {3} and c[3] == 3;
    t.tick();
    assert len(c) == 0 and 3 not in c;
}

test "ttl lru order and expire()" {
    t = Timer();
    c = TTLCache(maxsize=2, ttl=10.0, timer=t);
    c[1] = 1;
    c[2] = 2;
    c[1];
    c[3] = 3;
    assert keyset(c) == {1, 3};
    t.tick(5.0);
    c[4] = 4;
    assert keyset(c) == {3, 4};
    t.tick(5.0);
    gone = c.expire();
    assert gone == [(3, 3)];
    assert keyset(c) == {4} and c.currsize == 1;
    c[5] = 5;
    t.tick(20.0);
    assert len(c.expire()) == 2 and len(c) == 0;
    c[6] = 6;
    t.tick(10.0);
    assert raises(lambda -> any { del c[6]; return None; }, KeyError);
}

test "hashkey and typedkey" {
    assert hashkey() == hashkey();
    assert hash(hashkey()) == hash(hashkey());
    assert hashkey(1, 2, 3) == hashkey(1, 2, 3);
    assert hashkey(1, 2, 3) != hashkey(3, 2, 1);
    assert hashkey(1, foo="bar") == hashkey(1, foo="bar");
    assert hashkey(1, foo="bar") != hashkey(1, foo="baz");
    assert hashkey(a=1, b=2) == hashkey(b=2, a=1);
    assert hashkey(1, a=2) != hashkey(1, 2);
    assert hashkey(1) == hashkey(1.0);
    assert typedkey(1) != typedkey(1.0);
    assert typedkey(1, x=1) != typedkey(1, x=1.0);
    assert typedkey("a", x=2) == typedkey("a", x=2);
    assert methodkey(object(), 1, 2) == hashkey(1, 2);
    assert raises(lambda -> any { return hash(hashkey([])); }, TypeError);
    d: dict[any, int] = {hashkey(1, k="v"): 7};
    assert d[hashkey(1, k="v")] == 7;
}
