"""aidan46/orderbook-rs#23 — BookSide ladder before OSP lift.

M0 stabilizes get_best_price and reinsertion of emptied price levels.
Hand-rolled price ladder: parent/next pointer maps and deque reach walks.
"""

node PriceLevel {
    has price: int;
    has qty: int = 0;
}

edge WorseThan: PriceLevel --> PriceLevel {}

walker ReachWalk {
    has claimed: dict[int, bool] = {};
    has found: list[int] = [];
    has max_hops: int = 16;
    has depth: int = 0;

    can step with PriceLevel entry {
        if here.price in self.claimed { skip; }
        self.claimed[here.price] = True;
        self.found.append(here.price);
        if self.depth >= self.max_hops { skip; }
        self.depth = self.depth + 1;
        visit :0: [here ->:WorseThan:->][?:PriceLevel];
    }
}

obj BookSide {
    has side: str;
    has best: PriceLevel | None = None;
    has levels: dict[int, PriceLevel] = {};
    has orders: dict[int, tuple[int, int]] = {};

    def _is_better(a: int, b: int) -> bool {
        if self.side == "ask" { return a < b; }
        return a > b;
    }

    def _attach_price(lvl: PriceLevel) -> None {
        price = lvl.price;
        if self.best is None {
            self.best = lvl;
            return;
        }
        if self._is_better(price, self.best.price) {
            lvl +>:WorseThan:+> self.best;
            self.best = lvl;
            return;
        }
        cur = self.best;
        while True {
            nxt_list = [cur ->:WorseThan:->][?:PriceLevel];
            if len(nxt_list) == 0 { break; }
            nxt = nxt_list[0];
            if self.side == "ask" {
                if not (nxt.price < price) { break; }
            } elif not (nxt.price > price) {
                break;
            }
            cur = nxt;
        }
        after_list = [cur ->:WorseThan:->][?:PriceLevel];
        if len(after_list) > 0 {
            after = after_list[0];
            cur del ->:WorseThan:-> after;
            lvl +>:WorseThan:+> after;
        }
        cur +>:WorseThan:+> lvl;
    }

    def _detach_price(lvl: PriceLevel) -> None {
        price = lvl.price;
        prevs = [lvl <-:WorseThan:<-][?:PriceLevel];
        nxts = [lvl ->:WorseThan:->][?:PriceLevel];
        prev_n: PriceLevel | None = None;
        nxt_n: PriceLevel | None = None;
        if len(prevs) > 0 { prev_n = prevs[0]; }
        if len(nxts) > 0 { nxt_n = nxts[0]; }
        if prev_n is not None {
            prev_n del ->:WorseThan:-> lvl;
            if nxt_n is not None {
                prev_n +>:WorseThan:+> nxt_n;
            }
        } else {
            self.best = nxt_n;
        }
        if nxt_n is not None {
            lvl del ->:WorseThan:-> nxt_n;
        }
        del lvl;
        self.levels.pop(price, None);
    }

    def insert(order: dict) -> None {
        oid = order["id"];
        price = order["price"];
        qty = order["qty"];
        if price in self.levels {
            self.levels[price].qty += qty;
        } else {
            lvl = PriceLevel(price=price, qty=qty);
            root ++> lvl;
            self.levels[price] = lvl;
            self._attach_price(lvl);
        }
        self.orders[oid] = (price, qty);
    }

    def remove(order_id: int) -> None {
        hit = self.orders.pop(order_id, None);
        if hit is None { return; }
        price = hit[0];
        qty = hit[1];
        lvl = self.levels.get(price, None);
        if lvl is None { return; }
        lvl.qty -= qty;
        if lvl.qty <= 0 {
            self._detach_price(lvl);
        }
    }

    def get_best_price() -> int | None {
        if self.best is None { return None; }
        return self.best.price;
    }

    def get_total_qty(price: int) -> int | None {
        lvl = self.levels.get(price, None);
        if lvl is None { return None; }
        return lvl.qty;
    }

    def reachable_prices(max_hops: int = 16) -> list[int] {
        if self.best is None { return []; }
        w = self.best spawn ReachWalk(claimed={}, found=[], max_hops=max_hops, depth=0);
        return sorted(w.found);
    }
}

test "diamond revisit claim skip on reach walk" {
    b = BookSide(side="ask");
    b.insert({"id": 1, "price": 10, "qty": 1});
    b.insert({"id": 2, "price": 20, "qty": 1});
    b.insert({"id": 3, "price": 30, "qty": 1});
    b.insert({"id": 4, "price": 40, "qty": 1});
    b.insert({"id": 5, "price": 50, "qty": 1});
    assert b.reachable_prices(max_hops=0) == [10];
    assert b.reachable_prices(max_hops=2) == [10, 20, 30];
    assert b.reachable_prices(max_hops=16) == [10, 20, 30, 40, 50];
    assert b.reachable_prices(max_hops=16) == b.reachable_prices(max_hops=16);
}

test "unknown id tolerance" {
    b = BookSide(side="bid");
    b.insert({"id": 1, "price": 50, "qty": 2});
    b.remove(404);
    b.remove(0);
    assert b.get_best_price() == 50;
    assert b.get_total_qty(50) == 2;
    assert b.get_total_qty(99) is None;
    assert b.reachable_prices() == [50];
}

test "reinsert emptied ask level" {
    b = BookSide(side="ask");
    b.insert({"id": 1, "price": 100, "qty": 5});
    b.insert({"id": 2, "price": 110, "qty": 1});
    b.remove(1);
    assert b.get_best_price() == 110;
    assert b.get_total_qty(100) is None;
    b.insert({"id": 3, "price": 100, "qty": 3});
    assert b.get_best_price() == 100;
    assert b.get_total_qty(100) == 3;
    assert b.reachable_prices() == [100, 110];
}

test "partial removal keeps ladder level" {
    b = BookSide(side="ask");
    b.insert({"id": 1, "price": 100, "qty": 2});
    b.insert({"id": 2, "price": 100, "qty": 3});
    b.insert({"id": 3, "price": 105, "qty": 1});
    b.remove(1);
    assert b.get_best_price() == 100;
    assert b.get_total_qty(100) == 3;
    assert b.reachable_prices() == [100, 105];
}

test "detach middle ask level" {
    b = BookSide(side="ask");
    b.insert({"id": 1, "price": 100, "qty": 1});
    b.insert({"id": 2, "price": 110, "qty": 1});
    b.insert({"id": 3, "price": 105, "qty": 1});
    b.remove(2);
    assert b.get_best_price() == 100;
    assert b.get_total_qty(110) is None;
    assert b.get_total_qty(105) == 1;
    assert b.reachable_prices() == [100, 105];
}

test "empty book and remove best promotion" {
  empty = BookSide(side="bid");
    assert empty.get_best_price() is None;
    assert empty.reachable_prices() == [];
    assert empty.get_total_qty(1) is None;
    b = BookSide(side="bid");
    b.insert({"id": 1, "price": 105, "qty": 1});
    b.insert({"id": 2, "price": 100, "qty": 1});
    b.remove(1);
    assert b.get_best_price() == 100;
    assert b.reachable_prices() == [100];
}
