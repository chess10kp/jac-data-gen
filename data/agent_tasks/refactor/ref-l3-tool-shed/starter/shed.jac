"""Community tool shed: members borrow tools for a number of days; damaged tools go to repair."""

obj ToolShed {
    has name: str;
    has limit: int = 2;
    has labels: dict[str, str] = {};
    has condition: dict[str, str] = {};
    has borrower: dict[str, str] = {};
    has due: dict[str, int] = {};

    def register(code: str, name: str) -> bool {
        if code in self.labels {
            return False;
        }
        self.labels[code] = name;
        self.condition[code] = "ok";
        return True;
    }

    def checkout(card: str, code: str, day: int, days: int) -> str {
        if code not in self.labels {
            return "unknown tool";
        }
        if self.condition[code] != "ok" {
            return "unavailable";
        }
        if code in self.borrower {
            return "already lent";
        }
        held = 0;
        for c in self.borrower {
            if self.borrower[c] == card {
                held += 1;
            }
        }
        if held >= self.limit {
            return "limit reached";
        }
        self.borrower[code] = card;
        self.due[code] = day + days;
        return "ok";
    }

    def give_back(code: str, damaged: bool) -> bool {
        if code not in self.borrower {
            return False;
        }
        del self.borrower[code];
        del self.due[code];
        if damaged {
            self.condition[code] = "repair";
        }
        return True;
    }

    def repair(code: str) -> bool {
        if code not in self.labels or self.condition[code] != "repair" {
            return False;
        }
        self.condition[code] = "ok";
        return True;
    }

    def retire(code: str) -> bool {
        if code not in self.labels or code in self.borrower {
            return False;
        }
        if self.condition[code] == "retired" {
            return False;
        }
        self.condition[code] = "retired";
        return True;
    }

    def status(code: str) -> str {
        if code not in self.labels {
            return "unknown";
        }
        if self.condition[code] != "ok" {
            return self.condition[code];
        }
        if code in self.borrower {
            return "lent";
        }
        return "available";
    }

    def on_loan(card: str) -> list[str] {
        out: list[str] = [];
        for c in self.borrower {
            if self.borrower[c] == card {
                out.append(c);
            }
        }
        return sorted(out);
    }

    def overdue(today: int) -> list[str] {
        days: list[int] = [];
        for c in self.due {
            if self.due[c] < today and self.due[c] not in days {
                days.append(self.due[c]);
            }
        }
        out: list[str] = [];
        for d in sorted(days) {
            codes: list[str] = [];
            for c in self.due {
                if self.due[c] == d {
                    codes.append(c);
                }
            }
            for c in sorted(codes) {
                out.append(self.borrower[c] + ":" + c);
            }
        }
        return out;
    }
}
