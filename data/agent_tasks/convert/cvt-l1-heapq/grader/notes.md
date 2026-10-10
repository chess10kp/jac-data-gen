# cvt-l1-heapq
Source: CPython v3.12.7 Lib/heapq.py (PSF-2.0), trimmed (no merge, no C accelerator import).
Hidden tests port TestHeap from test_heapq.py with seeded RNGs (merge/C/error-handling classes dropped)
plus tie-stability for nsmallest/nlargest and explicit heapreplace cases.
Quirk: placement pinned to server in jac.toml (key calls through a value are un-lowerable natively).
Negatives: siftup picks larger child, inverted heappushpop guard, forward-order heapify,
nlargest ascending sort, nsmallest n==1 uses max.
