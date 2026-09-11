"""Reference harness for iss_aidan46__orderbook-rs__23."""
import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "_mod",
    Path(__file__).with_name("iss_aidan46__orderbook-rs__23.py"),
)
_mod = importlib.util.module_from_spec(_spec)
assert _spec.loader is not None
_spec.loader.exec_module(_mod)
asks = _mod.BookSide("ask")
asks.insert({"id": 1, "price": 69, "qty": 420})
asks.insert({"id": 2, "price": 70, "qty": 420})
assert asks.get_best_price() == 69
assert asks.get_total_qty(69) == 420
assert asks.get_total_qty(70) == 420
assert asks.get_total_qty(999) is None

bids = _mod.BookSide("bid")
bids.insert({"id": 1, "price": 69, "qty": 420})
bids.insert({"id": 2, "price": 70, "qty": 420})
assert bids.get_best_price() == 70
assert bids.get_total_qty(69) == 420
assert bids.get_total_qty(70) == 420

multi_ask = _mod.BookSide("ask")
for oid, price in [(1, 105), (2, 103), (3, 104)]:
    multi_ask.insert({"id": oid, "price": price, "qty": 420})
assert multi_ask.get_best_price() == 103
assert multi_ask.reachable_prices() == [103, 104, 105]
assert multi_ask.reachable_prices(max_hops=1) == [103, 104]

multi_bid = _mod.BookSide("bid")
for oid, price in [(1, 100), (2, 102), (3, 101)]:
    multi_bid.insert({"id": oid, "price": price, "qty": 420})
assert multi_bid.get_best_price() == 102
assert multi_bid.reachable_prices() == [100, 101, 102]

multi_ask.remove(2)
assert multi_ask.get_best_price() == 104
assert multi_ask.reachable_prices() == [104, 105]
assert multi_ask.get_total_qty(103) is None

refill = _mod.BookSide("ask")
refill.insert({"id": 1, "price": 100, "qty": 5})
refill.remove(1)
assert refill.get_best_price() is None
assert refill.get_total_qty(100) is None
assert refill.reachable_prices() == []
refill.insert({"id": 2, "price": 100, "qty": 3})
assert refill.get_best_price() == 100
assert refill.get_total_qty(100) == 3
assert refill.reachable_prices() == [100]

stacked = _mod.BookSide("bid")
stacked.insert({"id": 1, "price": 69, "qty": 420})
stacked.insert({"id": 2, "price": 69, "qty": 420})
assert stacked.get_total_qty(69) == 840
stacked.remove(1)
assert stacked.get_best_price() == 69
assert stacked.get_total_qty(69) == 420

empty_ask = _mod.BookSide("ask")
empty_bid = _mod.BookSide("bid")
assert empty_ask.get_best_price() is None
assert empty_bid.get_best_price() is None
assert empty_ask.reachable_prices() == []
empty_ask.remove(404)
print("iss_aidan46__orderbook-rs__23 ref OK")
