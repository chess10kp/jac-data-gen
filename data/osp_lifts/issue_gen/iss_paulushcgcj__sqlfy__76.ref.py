"""Reference harness: exercises every public function of iss_paulushcgcj__sqlfy__76."""
import importlib.util
import sys
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "sq76", Path(__file__).parent / "iss_paulushcgcj__sqlfy__76.py"
)
mod = importlib.util.module_from_spec(spec)
sys.modules["sq76"] = mod
spec.loader.exec_module(mod)

s = mod.SchemaGraph()
for t in ("users", "orders", "order_items", "audit"):
    s.add_table(t)
s.add_column("users", "email")
s.add_column("users", "id")
s.add_column("orders", "user_id")
s.add_column("orders", "total")
s.add_fk("orders", "users")           # orders references users
s.add_fk("order_items", "orders")
s.add_fk("audit", "users")

# Downstream: what breaks if users changes (depth 3 default).
hit = s.impact("users")
assert hit == ["audit", "order_items", "orders", "orders.total",
               "orders.user_id", "users", "users.email", "users.id"], hit
assert "orders.user_id" in hit and "audit" in hit

# Depth cut: at depth 1 only direct dependents plus their columns.
hit1 = s.impact("users", depth=1)
assert "orders" in hit1 and "order_items" not in hit1, hit1

# Upstream: what orders depends on.
up = s.impact("orders", direction="upstream")
assert "users" in up and "users.email" in up and "order_items" not in up, up

# Column anchor: impact of a column is itself + its table's dependents chain.
col = s.impact("orders.total", direction="downstream", depth=3)
assert col == ["order_items", "orders", "orders.total",
               "orders.user_id"], col

counts = s.counts_by_kind(hit)
assert counts["table"] == 4 and counts["column"] == 4, counts

# Errors.
try:
    s.impact("ghost")
    raise AssertionError("expected KeyError")
except KeyError:
    pass
try:
    s.add_fk("orders", "nope")
    raise AssertionError("expected KeyError")
except KeyError:
    pass
try:
    s.add_table("users")
    raise AssertionError("expected ValueError")
except ValueError:
    pass

print("sqlfy 76 ref OK")
