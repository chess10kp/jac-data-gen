"""Nested product catalog lifted to OSP.

Categories are ``Category`` nodes; ``FiledUnder`` edges point from a
subcategory to its parent. Subtotals fold bottom-up in exit abilities;
stock counts and leaf discovery sweep with explicit claim-map cycle policy.
"""

node Category {
    has name: str;
    has prices: list[int];       # payload: item prices stocked here
    has value_total: int = 0;    # staging: subtree value, folded at exit
    has branch_deep: int = 0;    # staging: longest nesting line, folded
}

edge FiledUnder: Category --> Category {}

"""Build the fixture catalog deterministically; returns the root category."""
def build_catalog() -> Category {
    root ++> (catalog := Category(name="catalog", prices=[]));
    root ++> (electronics := Category(name="electronics", prices=[250]));
    root ++> (audio := Category(name="audio", prices=[]));
    root ++> (books := Category(name="books", prices=[30]));
    root ++> (fiction := Category(name="fiction", prices=[12, 14]));
    root ++> (headphones := Category(name="headphones", prices=[99, 149]));
    electronics +>:FiledUnder:+> catalog;
    audio +>:FiledUnder:+> electronics;
    books +>:FiledUnder:+> catalog;
    fiction +>:FiledUnder:+> books;
    headphones +>:FiledUnder:+> audio;
    return catalog;
}

"""Create a subcategory under `parent` (None for catalog root)."""
def add_category(parent: Category | None, name: str) -> Category {
    root ++> (cat := Category(name=name, prices=[]));
    if parent is not None {
        cat +>:FiledUnder:+> parent;
    }
    return cat;
}

"""Stock one item at `price` directly in `cat`."""
def stock_item(cat: Category, price: int) -> None {
    cat.prices.append(price);
}

walker ValueFold {
    """Exit folds subtree stock value and nesting depth bottom-up."""
    has claimed: dict[str, bool] = {};

    can descend with Category entry {
        if here.name in self.claimed {
            skip;
        }
        self.claimed[here.name] = True;
        visit [<-:FiledUnder:<-];
    }

    can fold with Category exit {
        total = 0;
        for p in here.prices {
            total += p;
        }
        best = 0;
        for s in [<-:FiledUnder:<-] {
            total += s.value_total;
            if s.branch_deep > best {
                best = s.branch_deep;
            }
        }
        here.value_total = total;
        here.branch_deep = 1 + best;
    }
}

walker StockSweep {
    """Collects per-category stock counts and leaf names."""
    has counts: list[int] = [];
    has leaves: list[str] = [];
    has claimed: dict[str, bool] = {};

    can sweep with Category entry {
        if here.name in self.claimed {
            skip;
        }
        self.claimed[here.name] = True;
        self.counts.append(len(here.prices));
        kids = [<-:FiledUnder:<-];
        if len(kids) == 0 {
            self.leaves.append(here.name);
        }
        visit [<-:FiledUnder:<-];
    }
}

"""Total value of everything stocked in `cat`'s subtree."""
def category_subtotal(cat: Category) -> int {
    cat spawn ValueFold();
    return cat.value_total;
}

"""Number of items stocked in `cat`'s subtree."""
def item_count(cat: Category) -> int {
    w = cat spawn StockSweep();
    total = 0;
    for c in w.counts {
        total += c;
    }
    return total;
}

"""Names of categories with no subcategories at or below base, sorted."""
def leaf_categories(base: Category) -> list[str] {
    w = base spawn StockSweep();
    return sorted(w.leaves);
}

"""Longest chain of nested subcategories starting at `cat` (it counts)."""
def priciest_branch(cat: Category) -> int {
    cat spawn ValueFold();
    return cat.branch_deep;
}
