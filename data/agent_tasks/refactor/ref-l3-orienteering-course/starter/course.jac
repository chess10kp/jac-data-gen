"""Orienteering course planner: controls worth points, one-way legs between them."""

obj Course {
    has name: str;
    has points: dict[str, int] = {};
    has legs: dict[str, dict[str, int]] = {};

    def add_control(code: str, points: int) -> bool {
        if code in self.points {
            return False;
        }
        self.points[code] = points;
        self.legs[code] = {};
        return True;
    }

    def add_leg(a: str, b: str, metres: int) -> bool {
        if a not in self.points or b not in self.points {
            return False;
        }
        self.legs[a][b] = metres;
        return True;
    }

    def reachable(start: str) -> list[str] {
        seen: list[str] = [start];
        todo: list[str] = [start];
        while len(todo) > 0 {
            cur = todo.pop(0);
            for nxt in self.legs.get(cur, {}) {
                if nxt not in seen {
                    seen.append(nxt);
                    todo.append(nxt);
                }
            }
        }
        return sorted([c for c in seen if c != start]);
    }

    def points_from(start: str) -> int {
        if start not in self.points {
            return 0;
        }
        total = self.points[start];
        for c in self.reachable(start) {
            total += self.points[c];
        }
        return total;
    }

    def longest_leg_from(code: str) -> int {
        best = 0;
        for m in self.legs.get(code, {}).values() {
            if m > best {
                best = m;
            }
        }
        return best;
    }
}
