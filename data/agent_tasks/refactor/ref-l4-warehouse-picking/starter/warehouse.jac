"""Warehouse picking: numbered aisles walked in order, bins on shelf levels, blocked bins are skipped."""

obj Warehouse {
    has name: str;
    has aisle_total: int = 0;
    has codes: list[str] = [];
    has aisle_of: dict[str, int] = {};
    has sku_of: dict[str, str] = {};
    has qty_of: dict[str, int] = {};
    has level_of: dict[str, int] = {};
    has state_of: dict[str, str] = {};

    """Add the next aisle at the far end; returns its number (1-based)."""
    def add_aisle -> int {
        self.aisle_total += 1;
        return self.aisle_total;
    }

    """Put a bin on a shelf level of an aisle. Bin codes are unique in the warehouse."""
    def stock(aisle: int, code: str, sku: str, qty: int, level: int) -> bool {
        if aisle < 1 or aisle > self.aisle_total or code in self.aisle_of {
            return False;
        }
        self.codes.append(code);
        self.aisle_of[code] = aisle;
        self.sku_of[code] = sku;
        self.qty_of[code] = qty;
        self.level_of[code] = level;
        self.state_of[code] = "open";
        return True;
    }

    def block_bin(code: str) -> bool {
        if code not in self.state_of or self.state_of[code] == "blocked" {
            return False;
        }
        self.state_of[code] = "blocked";
        return True;
    }

    def on_hand(sku: str) -> int {
        total = 0;
        for code in self.codes {
            if self.sku_of[code] == sku and self.state_of[code] == "open" {
                total += self.qty_of[code];
            }
        }
        return total;
    }

    """Bin codes of one aisle in pick order: lowest shelf level first, then the order they were stocked."""
    def _pick_order(aisle: int) -> list[str] {
        levels: list[int] = [];
        for c in self.codes {
            if self.aisle_of[c] == aisle and self.level_of[c] not in levels {
                levels.append(self.level_of[c]);
            }
        }
        out: list[str] = [];
        for lv in sorted(levels) {
            for c in self.codes {
                if self.aisle_of[c] == aisle and self.level_of[c] == lv {
                    out.append(c);
                }
            }
        }
        return out;
    }

    """Walk aisles from 1 until the order is filled, appending pick lines to `lines`.
    Returns the number of aisles entered; commit=False is a dry run."""
    def _walk(order: dict[str, int], commit: bool, lines: list[str]) -> int {
        want: dict[str, int] = {};
        for sku in order {
            want[sku] = order[sku];
        }
        entered = 0;
        for aisle in range(1, self.aisle_total + 1) {
            entered += 1;
            for code in self._pick_order(aisle) {
                sku = self.sku_of[code];
                need = want.get(sku, 0);
                if need > 0 and self.qty_of[code] > 0 and self.state_of[code] == "open" {
                    take = min(need, self.qty_of[code]);
                    want[sku] = need - take;
                    if commit {
                        self.qty_of[code] = self.qty_of[code] - take;
                    }
                    lines.append(f"A{aisle}/{code} {sku} x{take}");
                }
            }
            left = 0;
            for s in want {
                left += want[s];
            }
            if left == 0 {
                break;
            }
        }
        return entered;
    }

    """Pick an order, taking stock out of the bins; returns the pick lines."""
    def pick(order: dict[str, int]) -> list[str] {
        lines: list[str] = [];
        self._walk(order, True, lines);
        return lines;
    }

    """How many aisles a picker would enter to fill the order (no stock is taken)."""
    def aisles_needed(order: dict[str, int]) -> int {
        lines: list[str] = [];
        return self._walk(order, False, lines);
    }
}
