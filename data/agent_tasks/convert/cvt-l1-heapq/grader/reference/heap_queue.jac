"""Heap queue (priority queue) algorithms over plain lists.

A heap is a list where heap[k] <= heap[2*k+1] and heap[k] <= heap[2*k+2] for
every k, so heap[0] is always the smallest item. Ported from CPython's heapq
(pure-Python implementation, without `merge`).
"""

"""Move the item at `pos` up towards `startpos` until its parent is not larger."""
def _siftdown(heap: list[any], startpos: int, pos: int) {
    newitem = heap[pos];
    while pos > startpos {
        parentpos = (pos - 1) >> 1;
        parent = heap[parentpos];
        if newitem < parent {
            heap[pos] = parent;
            pos = parentpos;
            continue;
        }
        break;
    }
    heap[pos] = newitem;
}

"""Bubble the smaller child up from `pos` to a leaf, then sift the old item down."""
def _siftup(heap: list[any], pos: int) {
    endpos = len(heap);
    startpos = pos;
    newitem = heap[pos];
    childpos = 2 * pos + 1;
    while childpos < endpos {
        rightpos = childpos + 1;
        if rightpos < endpos and not heap[childpos] < heap[rightpos] {
            childpos = rightpos;
        }
        heap[pos] = heap[childpos];
        pos = childpos;
        childpos = 2 * pos + 1;
    }
    heap[pos] = newitem;
    _siftdown(heap, startpos, pos);
}

def _siftdown_max(heap: list[any], startpos: int, pos: int) {
    newitem = heap[pos];
    while pos > startpos {
        parentpos = (pos - 1) >> 1;
        parent = heap[parentpos];
        if parent < newitem {
            heap[pos] = parent;
            pos = parentpos;
            continue;
        }
        break;
    }
    heap[pos] = newitem;
}

def _siftup_max(heap: list[any], pos: int) {
    endpos = len(heap);
    startpos = pos;
    newitem = heap[pos];
    childpos = 2 * pos + 1;
    while childpos < endpos {
        rightpos = childpos + 1;
        if rightpos < endpos and not heap[rightpos] < heap[childpos] {
            childpos = rightpos;
        }
        heap[pos] = heap[childpos];
        pos = childpos;
        childpos = 2 * pos + 1;
    }
    heap[pos] = newitem;
    _siftdown_max(heap, startpos, pos);
}

def _heapify_max(x: list[any]) {
    for i in reversed(range(len(x) // 2)) {
        _siftup_max(x, i);
    }
}

def _heapreplace_max(heap: list[any], item: any) -> any {
    returnitem = heap[0];
    heap[0] = item;
    _siftup_max(heap, 0);
    return returnitem;
}

"""Push `item` onto `heap`, keeping the heap invariant."""
def heappush(heap: list[any], item: any) {
    heap.append(item);
    _siftdown(heap, 0, len(heap) - 1);
}

"""Pop and return the smallest item (IndexError on an empty heap)."""
def heappop(heap: list[any]) -> any {
    lastelt = heap.pop();
    if heap {
        returnitem = heap[0];
        heap[0] = lastelt;
        _siftup(heap, 0);
        return returnitem;
    }
    return lastelt;
}

"""Pop the smallest item, then push `item` (the result may be larger than `item`)."""
def heapreplace(heap: list[any], item: any) -> any {
    returnitem = heap[0];
    heap[0] = item;
    _siftup(heap, 0);
    return returnitem;
}

"""Fast heappush followed by heappop."""
def heappushpop(heap: list[any], item: any) -> any {
    if heap and heap[0] < item {
        (item, heap[0]) = (heap[0], item);
        _siftup(heap, 0);
    }
    return item;
}

"""Rearrange `x` into a heap, in place, in linear time."""
def heapify(x: list[any]) {
    for i in reversed(range(len(x) // 2)) {
        _siftup(x, i);
    }
}

"""The `n` smallest items of `iterable`; same as sorted(iterable, key=key)[:n]."""
def nsmallest(n: int, iterable: list[any], key: any = None) -> list[any] {
    if n == 1 {
        if len(iterable) == 0 {
            return [];
        }
        return [min(iterable, key=key)];
    }
    if n >= len(iterable) {
        return sorted(iterable, key=key)[:n];
    }
    if n <= 0 {
        return [];
    }
    # Max-heap of the n best (key, order, elem) seen so far; `order` breaks ties
    # so the result is stable and elements themselves are never compared.
    result: list[tuple[any, int, any]] = [];
    for (i, elem) in enumerate(iterable[:n]) {
        result.append((elem if key is None else key(elem), i, elem));
    }
    _heapify_max(result);
    top = result[0][0];
    order = n;
    for elem in iterable[n:] {
        k = elem if key is None else key(elem);
        if k < top {
            _heapreplace_max(result, (k, order, elem));
            top = result[0][0];
            order += 1;
        }
    }
    result.sort();
    return [rec[2] for rec in result];
}

"""The `n` largest items of `iterable`; same as sorted(iterable, key=key, reverse=True)[:n]."""
def nlargest(n: int, iterable: list[any], key: any = None) -> list[any] {
    if n == 1 {
        if len(iterable) == 0 {
            return [];
        }
        return [max(iterable, key=key)];
    }
    if n >= len(iterable) {
        return sorted(iterable, key=key, reverse=True)[:n];
    }
    if n <= 0 {
        return [];
    }
    # Min-heap of the n best; negative orders keep earlier items first on ties.
    result: list[tuple[any, int, any]] = [];
    for (i, elem) in enumerate(iterable[:n]) {
        result.append((elem if key is None else key(elem), -i, elem));
    }
    heapify(result);
    top = result[0][0];
    order = -n;
    for elem in iterable[n:] {
        k = elem if key is None else key(elem);
        if top < k {
            heapreplace(result, (k, order, elem));
            top = result[0][0];
            order -= 1;
        }
    }
    result.sort(reverse=True);
    return [rec[2] for rec in result];
}
