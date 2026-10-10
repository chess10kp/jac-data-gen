"""Apple orchard: blocks of numbered rows, trees in slots along a row, harvest forecasts per block."""

glob MATURE_KG: dict[str, float] = {"gala": 40.0, "fuji": 50.0, "braeburn": 35.0, "honeycrisp": 30.0};

"""Fraction of the mature yield a tree gives at a given age in years."""
def age_factor(age: int) -> float {
    if age < 3 {
        return 0.0;
    }
    if age < 6 {
        return 0.5;
    }
    if age <= 20 {
        return 1.0;
    }
    return 0.75;
}

obj Orchard {
    has name: str;
    has blocks: list[str] = [];
    has trees: dict[str, dict[str, any]] = {};

    def add_block(block: str) -> bool {
        if block in self.blocks {
            return False;
        }
        self.blocks.append(block);
        return True;
    }

    """Plant a tree; tags are unique across the orchard and a slot holds one tree."""
    def plant(block: str, row: int, slot: int, tag: str, variety: str, age: int) -> bool {
        if block not in self.blocks or tag in self.trees or variety not in MATURE_KG {
            return False;
        }
        if self.tree_at(block, row, slot) != "" {
            return False;
        }
        self.trees[tag] = {"block": block, "row": row, "slot": slot, "variety": variety, "age": age, "sick": False};
        return True;
    }

    def tree_at(block: str, row: int, slot: int) -> str {
        for tag in self.trees {
            t = self.trees[tag];
            if t["block"] == block and t["row"] == row and t["slot"] == slot {
                return tag;
            }
        }
        return "";
    }

    def mark_diseased(tag: str) -> bool {
        if tag not in self.trees {
            return False;
        }
        self.trees[tag]["sick"] = True;
        return True;
    }

    """Every tree gets a year older."""
    def next_season() {
        for tag in self.trees {
            self.trees[tag]["age"] = self.trees[tag]["age"] + 1;
        }
    }

    """Expected kg from the healthy trees of a block."""
    def forecast(block: str) -> float {
        total = 0.0;
        for tag in self.trees {
            t = self.trees[tag];
            if t["block"] == block and not t["sick"] {
                total += MATURE_KG[t["variety"]] * age_factor(t["age"]);
            }
        }
        return total;
    }

    """"variety kg" lines for a block's healthy trees, by variety name."""
    def variety_totals(block: str) -> list[str] {
        kg: dict[str, float] = {};
        for tag in self.trees {
            t = self.trees[tag];
            if t["block"] == block and not t["sick"] {
                kg[t["variety"]] = kg.get(t["variety"], 0.0) + MATURE_KG[t["variety"]] * age_factor(t["age"]);
            }
        }
        return [f"{v} {kg[v]:.1f}" for v in sorted(kg.keys())];
    }

    """Healthy tree count per row number of a block, ascending by row."""
    def healthy_rows(block: str) -> list[int] {
        counts: dict[int, int] = {};
        for tag in self.trees {
            t = self.trees[tag];
            if t["block"] == block {
                if t["row"] not in counts {
                    counts[t["row"]] = 0;
                }
                if not t["sick"] {
                    counts[t["row"]] = counts[t["row"]] + 1;
                }
            }
        }
        return [counts[r] for r in sorted(counts.keys())];
    }
}
