"""Orienteering course planner: controls worth points, one-way legs between them."""

class Course {
    def init(self: Course, name: str) {
        self.name = name;
        self.points: dict[str, int] = {};
        self.legs: dict[str, list[tuple[str, int]]] = {};
    }

    def add_control(self: Course, code: str, points: int) -> bool {
        if code in self.points {
            return False;
        }
        self.points[code] = points;
        self.legs[code] = [];
        return True;
    }

    def add_leg(self: Course, a: str, b: str, metres: int) -> bool {
        if a not in self.points or b not in self.points {
            return False;
        }
        self.legs[a].append((b, metres));
        return True;
    }

    def reachable(self: Course, start: str) -> list[str] {
        seen: list[str] = [start];
        todo: list[str] = [start];
        while len(todo) > 0 {
            cur = todo.pop(0);
            for (nxt, _) in self.legs.get(cur, []) {
                if nxt not in seen {
                    seen.append(nxt);
                    todo.append(nxt);
                }
            }
        }
        return sorted([c for c in seen if c != start]);
    }

    def points_from(self: Course, start: str) -> int {
        if start not in self.points {
            return 0;
        }
        total = self.points[start];
        for c in self.reachable(start) {
            total += self.points[c];
        }
        return total;
    }

    def longest_leg_from(self: Course, code: str) -> int {
        best = 0;
        for (_, m) in self.legs.get(code, []) {
            if m > best {
                best = m;
            }
        }
        return best;
    }
}
