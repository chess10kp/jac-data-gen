"""aidan46/orderbook-rs#23 — BookSide ladder before OSP lift.

M0 stabilizes get_best_price and reinsertion of emptied price levels.
Hand-rolled price ladder: parent/next pointer maps and deque reach walks.
"""

from __future__ import annotations

from collections import deque


class BookSide:
    def __init__(self, side: str) -> None:
        self.side = side
        self.levels: dict[int, int] = {}
        self.orders: dict[int, tuple[int, int]] = {}
        self.next_worse: dict[int, int | None] = {}
        self.prev_better: dict[int, int | None] = {}
        self.best: int | None = None

    def _is_better(self, a: int, b: int) -> bool:
        return a < b if self.side == "ask" else a > b

    def _attach_price(self, price: int) -> None:
        if self.best is None:
            self.best = price
            self.next_worse[price] = None
            self.prev_better[price] = None
            return
        if self._is_better(price, self.best):
            self.prev_better[self.best] = price
            self.next_worse[price] = self.best
            self.prev_better[price] = None
            self.best = price
            return
        cur = self.best
        nxt = self.next_worse.get(cur)
        while nxt is not None:
            if self.side == "ask":
                if not (nxt < price):
                    break
            elif not (nxt > price):
                break
            cur = nxt
            nxt = self.next_worse.get(cur)
        after = self.next_worse.get(cur)
        self.next_worse[cur] = price
        self.prev_better[price] = cur
        self.next_worse[price] = after
        if after is not None:
            self.prev_better[after] = price

    def _detach_price(self, price: int) -> None:
        prev_b = self.prev_better.pop(price, None)
        nxt_w = self.next_worse.pop(price, None)
        if prev_b is not None:
            self.next_worse[prev_b] = nxt_w
        else:
            self.best = nxt_w
        if nxt_w is not None:
            self.prev_better[nxt_w] = prev_b

    def insert(self, order: dict) -> None:
        oid, price, qty = order["id"], order["price"], order["qty"]
        if price in self.levels:
            self.levels[price] += qty
        else:
            self.levels[price] = qty
            self._attach_price(price)
        self.orders[oid] = (price, qty)

    def remove(self, order_id: int) -> None:
        hit = self.orders.pop(order_id, None)
        if hit is None:
            return
        price, qty = hit
        self.levels[price] -= qty
        if self.levels[price] <= 0:
            del self.levels[price]
            self._detach_price(price)

    def get_best_price(self) -> int | None:
        return self.best

    def get_total_qty(self, price: int) -> int | None:
        qty = self.levels.get(price)
        return qty if qty is not None else None

    def reachable_prices(self, max_hops: int = 16) -> list[int]:
        if self.best is None:
            return []
        out: list[int] = []
        q: deque[tuple[int, int]] = deque([(self.best, 0)])
        seen: set[int] = set()
        while q:
            cur, depth = q.popleft()
            if cur in seen:
                continue
            seen.add(cur)
            out.append(cur)
            if depth >= max_hops:
                continue
            nxt = self.next_worse.get(cur)
            if nxt is not None and nxt not in seen:
                q.append((nxt, depth + 1))
        return sorted(out)
