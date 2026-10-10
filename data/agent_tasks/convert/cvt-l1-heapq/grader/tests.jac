# Hidden tests: CPython Lib/test/test_heapq.py (v3.12.7) ported to Jac (merge excluded).
import random;
import from heap_queue { heappush, heappop, heapreplace, heappushpop, heapify, nsmallest, nlargest }

def is_heap(heap: list[any]) -> bool {
    for (pos, item) in enumerate(heap) {
        if pos and not heap[(pos - 1) >> 1] <= item {
            return False;
        }
    }
    return True;
}

def drain(heap: list[any]) -> list[any] {
    out: list[any] = [];
    while heap {
        out.append(heappop(heap));
    }
    return out;
}

def mod_key(x: tuple[int, int]) -> int {
    return x[0] * 547 % 2000;
}

test "push pop keeps invariant and sorts" {
    rng = random.Random(1);
    heap: list[float] = [];
    data: list[float] = [];
    for i in range(256) {
        item = rng.random();
        data.append(item);
        heappush(heap, item);
        assert is_heap(heap);
    }
    results: list[float] = [];
    while heap {
        results.append(heappop(heap));
        assert is_heap(heap);
    }
    assert results == sorted(data);
}

test "heappop on empty raises IndexError" {
    raised = False;
    try { heappop([]); } except IndexError { raised = True; }
    assert raised;
    raised2 = False;
    try { heapreplace([], 1); } except IndexError { raised2 = True; }
    assert raised2;
}

test "heapify" {
    rng = random.Random(2);
    for size in list(range(30)) + [2000] {
        heap = [rng.random() for _ in range(size)];
        heapify(heap);
        assert is_heap(heap);
        assert len(heap) == size;
    }
}

test "naive nbest" {
    rng = random.Random(3);
    data = [rng.randrange(2000) for i in range(1000)];
    heap: list[int] = [];
    for item in data {
        heappush(heap, item);
        if len(heap) > 10 {
            heappop(heap);
        }
    }
    heap.sort();
    assert heap == sorted(data)[-10:];
}

test "nbest with heapreplace" {
    rng = random.Random(4);
    data = [rng.randrange(2000) for i in range(1000)];
    heap = data[:10];
    heapify(heap);
    for item in data[10:] {
        if item > heap[0] {
            heapreplace(heap, item);
        }
    }
    assert drain(heap) == sorted(data)[-10:];
}

test "nbest with pushpop" {
    rng = random.Random(5);
    data = [rng.randrange(2000) for i in range(1000)];
    heap = data[:10];
    heapify(heap);
    for item in data[10:] {
        heappushpop(heap, item);
    }
    assert drain(heap) == sorted(data)[-10:];
    assert heappushpop([], "x") == "x";
}

test "heappushpop edge cases" {
    h: list[float] = [];
    x = heappushpop(h, 10);
    assert len(h) == 0 and x == 10;
    h = [10];
    x = heappushpop(h, 10.0);
    assert h == [10] and x == 10.0;
    assert type(h[0]) is int and type(x) is float;
    h = [10];
    x = heappushpop(h, 9);
    assert h == [10] and x == 9;
    h = [10];
    x = heappushpop(h, 11);
    assert h == [11] and x == 10;
}

test "heapreplace returns old smallest" {
    h = [1, 5, 3];
    heapify(h);
    assert heapreplace(h, 0) == 1;
    assert h[0] == 0 and is_heap(h);
    assert heapreplace(h, 9) == 0;
    assert sorted(h) == [3, 5, 9] and is_heap(h);
}

test "heapsort" {
    rng = random.Random(6);
    for trial in range(100) {
        size = rng.randrange(50);
        data = [rng.randrange(25) for i in range(size)];
        heap: list[int] = [];
        if trial & 1 {
            heap = list(data);
            heapify(heap);
        } else {
            for item in data {
                heappush(heap, item);
            }
        }
        assert [heappop(heap) for i in range(size)] == sorted(data);
    }
}

test "nsmallest" {
    rng = random.Random(7);
    data = [(rng.randrange(2000), i) for i in range(1000)];
    for n in [0, 1, 2, 10, 100, 400, 999, 1000, 1100] {
        assert nsmallest(n, data) == sorted(data)[:n];
        assert nsmallest(n, data, key=mod_key) == sorted(data, key=mod_key)[:n];
    }
}

test "nlargest" {
    rng = random.Random(8);
    data = [(rng.randrange(2000), i) for i in range(1000)];
    for n in [0, 1, 2, 10, 100, 400, 999, 1000, 1100] {
        assert nlargest(n, data) == sorted(data, reverse=True)[:n];
        assert nlargest(n, data, key=mod_key) == sorted(data, key=mod_key, reverse=True)[:n];
    }
}

test "nsmallest and nlargest are stable on ties" {
    words = ["pear", "fig", "kiwi", "plum", "date", "lime", "apple", "yam"];
    assert nsmallest(3, words, key=len) == ["fig", "yam", "pear"];
    assert nlargest(3, words, key=len) == ["apple", "pear", "kiwi"];
    assert len(nsmallest(3, [])) == 0 and len(nlargest(1, [])) == 0;
}
