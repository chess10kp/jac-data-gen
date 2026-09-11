"""Reference harness for rec_09_catalog (deterministic fixture)."""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from rec_09_catalog import add_category, category_subtotal, item_count, leaf_categories, priciest_branch, stock_item

catalog = add_category(None, "catalog")
electronics = add_category(catalog, "electronics")
audio = add_category(electronics, "audio")
books = add_category(catalog, "books")
fiction = add_category(books, "fiction")
headphones = add_category(audio, "headphones")

stock_item(electronics, 250)
stock_item(headphones, 99)
stock_item(headphones, 149)
stock_item(fiction, 12)
stock_item(fiction, 14)
stock_item(books, 30)

subtotals = {"catalog": category_subtotal(catalog),
             "audio": category_subtotal(audio),
             "books": category_subtotal(books)}
print("subtotals:", subtotals)
assert subtotals == {"catalog": 554, "audio": 248, "books": 56}, subtotals

counts = {"catalog": item_count(catalog), "books": item_count(books),
          "headphones": item_count(headphones)}
print("item counts:", counts)
assert counts == {"catalog": 6, "books": 3, "headphones": 2}, counts

leaves = leaf_categories(catalog)
print("leaf_categories(catalog):", leaves)
assert leaves == ["fiction", "headphones"], leaves

branches = {"catalog": priciest_branch(catalog), "fiction": priciest_branch(fiction)}
print("priciest_branch:", branches)
assert branches == {"catalog": 4, "fiction": 1}, branches

# §5.4 invariant: acyclic by construction (add_category only links downward).
print("rec_09_catalog: all assertions passed")
